import 'package:intl/intl.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/db/metadata_mixin.dart';
import 'package:telegraph/features/time/models/session_model.dart';

class TimeDatabaseService with MetadataMixin {
  final DatabaseManager _dbManager;
  @override
  final MetadataService metadataService;

  TimeDatabaseService({
    required DatabaseManager dbManager,
    required this.metadataService,
  }) : _dbManager = dbManager;

  static const tableTime = 'time_sessions';
  static const tableJunction = 'time_session_tags';

  String get _durationSql =>
      "ROUND((julianday(IFNULL(end_time, 'now')) - julianday(start_time)) * 1440, 2)";

  Future<void> startSession(
    String notes,
    List<String> tags, {
    DateTime? startTime,
  }) async {
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      final id = await txn.insert(tableTime, {
        'start_time': (startTime ?? DateTime.now()).toIso8601String(),
        'notes': notes,
      });
      await metadataService.linkEntityToTags(
        txn,
        tableJunction,
        'time_id',
        id,
        tags,
        module: 'time',
      );
    });
  }

  Future<SessionModel?> stopSession({DateTime? stopTime}) async {
    final active = await getActiveSession();
    if (active == null) return null;
    final end = stopTime ?? DateTime.now();
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      await txn.delete(
        tableJunction,
        where: 'time_id = ?',
        whereArgs: [active.id],
      );
      await txn.delete(tableTime, where: 'id = ?', whereArgs: [active.id]);
      await saveSplittableEntity(
        db: txn,
        tableName: tableTime,
        tagJunctionTable: tableJunction,
        idColumn: 'time_id',
        module: 'time',
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
        tableName: tableTime,
        tagJunctionTable: tableJunction,
        idColumn: 'time_id',
        module: 'time',
        start: start,
        end: end,
        tags: tags,
        baseData: {'notes': notes},
      ),
    );
  }

  Future<SessionModel?> getActiveSession() async {
    final db = await _dbManager.database;
    final res = await db.rawQuery(
      "SELECT t.*, GROUP_CONCAT(tg.name, ' ') as tag_list FROM $tableTime t LEFT JOIN $tableJunction tj ON t.id = tj.time_id LEFT JOIN ${MetadataService.tableTags} tg ON tj.tag_id = tg.id WHERE t.end_time IS NULL GROUP BY t.id LIMIT 1",
    );
    return res.isEmpty
        ? null
        : SessionModel.fromMap(
            res.first,
            tags:
                (res.first['tag_list'] as String?)
                    ?.split(' ')
                    .where((t) => t.isNotEmpty)
                    .toList() ??
                [],
          );
  }

  /// ✅ Fixed: Added filtering by date and tag
  Future<List<SessionModel>> getSessions({DateTime? date, String? tag}) async {
    final db = await _dbManager.database;
    List<String> whereClauses = [];
    List<dynamic> args = [];

    if (date != null) {
      whereClauses.add("DATE(t.start_time) = ?");
      args.add(DateFormat('yyyy-MM-dd').format(date));
    }

    if (tag != null) {
      whereClauses.add(
        "t.id IN (SELECT time_id FROM $tableJunction tj JOIN ${MetadataService.tableTags} tg ON tj.tag_id = tg.id WHERE tg.name = ?)",
      );
      args.add(tag.toLowerCase().trim());
    }

    final whereStr = whereClauses.isEmpty
        ? ""
        : "WHERE ${whereClauses.join(" AND ")}";

    final res = await db.rawQuery('''
      SELECT t.*, GROUP_CONCAT(tg.name, ' ') as tag_list 
      FROM $tableTime t 
      LEFT JOIN $tableJunction tj ON t.id = tj.time_id 
      LEFT JOIN ${MetadataService.tableTags} tg ON tj.tag_id = tg.id 
      $whereStr
      GROUP BY t.id 
      ORDER BY t.start_time ASC
    ''', args);
    return res
        .map(
          (m) => SessionModel.fromMap(
            m,
            tags:
                (m['tag_list'] as String?)
                    ?.split(' ')
                    .where((t) => t.isNotEmpty)
                    .toList() ??
                [],
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTagWiseSummary({DateTime? date}) async {
    final db = await _dbManager.database;
    final where = date != null ? "WHERE DATE(t.start_time) = ?" : "";
    final res = await db.rawQuery(
      "SELECT tg.name as tag_name, COUNT(t.id) as session_count, SUM($_durationSql) as total_minutes FROM ${MetadataService.tableTags} tg JOIN $tableJunction tj ON tg.id = tj.tag_id JOIN $tableTime t ON tj.time_id = t.id $where GROUP BY tg.id, tg.name HAVING total_minutes > 0 ORDER BY total_minutes DESC",
      date != null ? [DateFormat('yyyy-MM-dd').format(date)] : [],
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

  Future<List<Map<String, dynamic>>> getHourlyDistribution({
    DateTime? date,
  }) async {
    final db = await _dbManager.database;
    final where = date != null ? "WHERE DATE(t.start_time) = ?" : "";
    final res = await db.rawQuery(
      "SELECT CAST(strftime('%H', t.start_time) AS INTEGER) as hour, COUNT(DISTINCT t.id) as count, SUM($_durationSql) as mins FROM $tableTime t $where GROUP BY hour ORDER BY hour",
      date != null ? [DateFormat('yyyy-MM-dd').format(date)] : [],
    );
    final map = {for (var r in res) r['hour'] as int: r};
    return List.generate(
      24,
      (h) => {
        'hour': h,
        'total_minutes': (map[h]?['mins'] as num?)?.toDouble() ?? 0.0,
        'session_count': map[h]?['count'] ?? 0,
      },
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await _dbManager.database;
    return await db.transaction((txn) async {
      await txn.delete(tableJunction, where: 'time_id = ?', whereArgs: [id]);
      return await txn.delete(tableTime, where: 'id = ?', whereArgs: [id]);
    });
  }
}
