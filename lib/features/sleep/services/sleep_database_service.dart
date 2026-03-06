import 'package:intl/intl.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/db/metadata_mixin.dart';
import 'package:telegraph/features/sleep/models/sleep_session_model.dart';

class SleepDatabaseService with MetadataMixin {
  final DatabaseManager _dbManager;
  @override
  final MetadataService metadataService;

  SleepDatabaseService({
    required DatabaseManager dbManager,
    required this.metadataService,
  }) : _dbManager = dbManager;

  static const tableSleep = 'sleep_sessions';
  static const tableJunction = 'sleep_session_tags';

  String get _durationSql =>
      "ROUND((julianday(IFNULL(end_time, 'now')) - julianday(start_time)) * 1440, 2)";

  Future<void> startSession(
    String notes,
    List<String> tags, {
    DateTime? startTime,
  }) async {
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      final id = await txn.insert(tableSleep, {
        'start_time': (startTime ?? DateTime.now()).toIso8601String(),
        'notes': notes,
      });
      await metadataService.linkEntityToTags(
        txn,
        tableJunction,
        'sleep_id',
        id,
        tags,
        module: 'sleep',
      );
    });
  }

  Future<SleepSessionModel?> stopSession({DateTime? stopTime}) async {
    final active = await getActiveSession();
    if (active == null) return null;
    final end = stopTime ?? DateTime.now();

    final db = await _dbManager.database;
    await db.transaction((txn) async {
      await txn.delete(
        tableJunction,
        where: 'sleep_id = ?',
        whereArgs: [active.id],
      );
      await txn.delete(tableSleep, where: 'id = ?', whereArgs: [active.id]);

      await saveSplittableEntity(
        db: txn,
        tableName: tableSleep,
        tagJunctionTable: tableJunction,
        idColumn: 'sleep_id',
        module: 'sleep',
        start: active.startTime,
        end: end,
        tags: active.tags,
        baseData: {'notes': active.notes},
      );
    });
    return active.copyWith(endTime: end);
  }

  Future<void> recordCompletedSession({
    required DateTime start,
    required DateTime end,
    required String notes,
    required List<String> tags,
  }) async {
    final db = await _dbManager.database;
    await db.transaction(
      (txn) => saveSplittableEntity(
        db: txn,
        tableName: tableSleep,
        tagJunctionTable: tableJunction,
        idColumn: 'sleep_id',
        module: 'sleep',
        start: start,
        end: end,
        tags: tags,
        baseData: {'notes': notes},
      ),
    );
  }

  Future<SleepSessionModel?> getActiveSession() async {
    final db = await _dbManager.database;
    final res = await db.rawQuery(
      "SELECT t.*, GROUP_CONCAT(tg.name, ' ') as tag_list FROM $tableSleep t LEFT JOIN $tableJunction tj ON t.id = tj.sleep_id LEFT JOIN ${MetadataService.tableTags} tg ON tj.tag_id = tg.id WHERE t.end_time IS NULL GROUP BY t.id LIMIT 1",
    );
    return res.isEmpty ? null : _mapToSession(res.first);
  }

  Future<List<SleepSessionModel>> getSessionsByDate(DateTime date) async {
    final db = await _dbManager.database;
    final res = await db.rawQuery(
      "SELECT t.*, GROUP_CONCAT(tg.name, ' ') as tag_list FROM $tableSleep t LEFT JOIN $tableJunction tj ON t.id = tj.sleep_id LEFT JOIN ${MetadataService.tableTags} tg ON tj.tag_id = tg.id WHERE DATE(t.start_time) = ? GROUP BY t.id ORDER BY t.start_time ASC",
      [DateFormat('yyyy-MM-dd').format(date)],
    );
    return res.map(_mapToSession).toList();
  }

  Future<List<Map<String, dynamic>>> getSleepSummary({DateTime? date}) async {
    final db = await _dbManager.database;
    final String where = date != null ? "WHERE DATE(t.start_time) = ?" : "";
    final args = date != null ? [DateFormat('yyyy-MM-dd').format(date)] : [];
    final res = await db.rawQuery(
      "SELECT COUNT(t.id) as session_count, SUM($_durationSql) as total_minutes, AVG($_durationSql) as avg_minutes FROM $tableSleep t $where HAVING total_minutes > 0",
      args,
    );
    return res.isEmpty
        ? [
            {'session_count': 0, 'total_minutes': 0.0, 'avg_minutes': 0.0},
          ]
        : res
              .map(
                (r) => {
                  'session_count': r['session_count'] ?? 0,
                  'total_minutes':
                      (r['total_minutes'] as num?)?.toDouble() ?? 0.0,
                  'avg_minutes': (r['avg_minutes'] as num?)?.toDouble() ?? 0.0,
                },
              )
              .toList();
  }

  Future<List<Map<String, dynamic>>> getTagWiseSummary({DateTime? date}) async {
    final db = await _dbManager.database;
    final String where = date != null ? "WHERE DATE(t.start_time) = ?" : "";
    final args = date != null ? [DateFormat('yyyy-MM-dd').format(date)] : [];
    final res = await db.rawQuery(
      "SELECT tg.name as tag_name, COUNT(t.id) as session_count, SUM($_durationSql) as total_minutes FROM ${MetadataService.tableTags} tg JOIN $tableJunction tj ON tg.id = tj.tag_id JOIN $tableSleep t ON tj.sleep_id = t.id $where GROUP BY tg.id, tg.name HAVING total_minutes > 0 ORDER BY total_minutes DESC",
      args,
    );
    return res
        .map(
          (r) => {
            'tag': r['tag_name'],
            'total_minutes': (r['total_minutes'] as num?)?.toDouble() ?? 0.0,
            'session_count': r['session_count'],
          },
        )
        .toList();
  }

  Future<int> deleteSession(int id) async {
    final db = await _dbManager.database;
    return await db.transaction((txn) async {
      await txn.delete(tableJunction, where: 'sleep_id = ?', whereArgs: [id]);
      return await txn.delete(tableSleep, where: 'id = ?', whereArgs: [id]);
    });
  }

  SleepSessionModel _mapToSession(Map<String, dynamic> map) {
    final tags =
        (map['tag_list'] as String?)
            ?.split(' ')
            .where((t) => t.isNotEmpty)
            .toList() ??
        [];
    return SleepSessionModel.fromMap(map, tags: tags);
  }
}
