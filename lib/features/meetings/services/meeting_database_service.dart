import 'package:intl/intl.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/db/metadata_mixin.dart';
import 'package:telegraph/features/meetings/models/meeting_model.dart';

class MeetingDatabaseService with MetadataMixin {
  final DatabaseManager _dbManager;
  @override
  final MetadataService metadataService;

  MeetingDatabaseService({
    required DatabaseManager dbManager,
    required this.metadataService,
  }) : _dbManager = dbManager;

  static const tableMeetings = 'meeting_sessions';
  static const tableJunctionTags = 'meeting_session_tags';
  static const tableJunctionParts = 'meeting_session_participants';

  Future<void> startMeeting(
    String notes,
    List<String> tags,
    List<String> participants, {
    DateTime? startTime,
  }) async {
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      final id = await txn.insert(tableMeetings, {
        'start_time': (startTime ?? DateTime.now()).toIso8601String(),
        'notes': notes,
      });
      await metadataService.linkEntityToTags(
        txn,
        tableJunctionTags,
        'meeting_id',
        id,
        tags,
        module: 'meeting',
      );
      await metadataService.linkEntityToParticipants(
        txn,
        tableJunctionParts,
        'meeting_id',
        id,
        participants,
        module: 'meeting',
      );
    });
  }

  Future<MeetingModel?> stopActiveMeeting({DateTime? stopTime}) async {
    final active = await getActiveMeeting();
    if (active == null) return null;
    final end = stopTime ?? DateTime.now();
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      await txn.delete(
        tableJunctionTags,
        where: 'meeting_id = ?',
        whereArgs: [active.id],
      );
      await txn.delete(
        tableJunctionParts,
        where: 'meeting_id = ?',
        whereArgs: [active.id],
      );
      await txn.delete(tableMeetings, where: 'id = ?', whereArgs: [active.id]);
      await saveSplittableEntity(
        db: txn,
        tableName: tableMeetings,
        tagJunctionTable: tableJunctionTags,
        participantJunctionTable: tableJunctionParts,
        idColumn: 'meeting_id',
        module: 'meeting',
        start: active.startTime,
        end: end,
        tags: active.tags,
        participants: active.participants,
        baseData: {'notes': active.notes},
      );
    });
    return active.copyWith(endTime: end);
  }

  Future<void> recordCompletedMeeting({
    required DateTime start,
    required DateTime end,
    required String notes,
    required List<String> tags,
    required List<String> participants,
  }) async {
    final db = await _dbManager.database;
    await db.transaction(
      (txn) => saveSplittableEntity(
        db: txn,
        tableName: tableMeetings,
        tagJunctionTable: tableJunctionTags,
        participantJunctionTable: tableJunctionParts,
        idColumn: 'meeting_id',
        module: 'meeting',
        start: start,
        end: end,
        tags: tags,
        participants: participants,
        baseData: {'notes': notes},
      ),
    );
  }

  Future<MeetingModel?> getActiveMeeting() async {
    final db = await _dbManager.database;
    final res = await db.rawQuery(
      "SELECT m.*, (SELECT GROUP_CONCAT(tg.name, ' ') FROM ${MetadataService.tableTags} tg JOIN $tableJunctionTags tj ON tg.id = tj.tag_id WHERE tj.meeting_id = m.id) as tag_list, (SELECT GROUP_CONCAT(p.name, ' ') FROM ${MetadataService.tableParticipants} p JOIN $tableJunctionParts pj ON p.id = pj.participant_id WHERE pj.meeting_id = m.id) as part_list FROM $tableMeetings m WHERE m.end_time IS NULL LIMIT 1",
    );
    return res.isEmpty ? null : _mapToMeeting(res.first);
  }

  /// ✅ Fixed: Added filtering by tag and participant
  Future<List<MeetingModel>> getMeetings({
    DateTime? date,
    String? tag,
    String? participant,
  }) async {
    final db = await _dbManager.database;
    List<String> whereClauses = [];
    List<dynamic> args = [];

    if (date != null) {
      whereClauses.add("DATE(m.start_time) = ?");
      args.add(DateFormat('yyyy-MM-dd').format(date));
    }
    if (tag != null) {
      whereClauses.add(
        "m.id IN (SELECT meeting_id FROM $tableJunctionTags tj JOIN ${MetadataService.tableTags} tg ON tj.tag_id = tg.id WHERE tg.name = ?)",
      );
      args.add(tag.toLowerCase().trim());
    }
    if (participant != null) {
      whereClauses.add(
        "m.id IN (SELECT meeting_id FROM $tableJunctionParts pj JOIN ${MetadataService.tableParticipants} p ON pj.participant_id = p.id WHERE p.name = ?)",
      );
      args.add(participant.toLowerCase().trim());
    }

    final whereStr = whereClauses.isEmpty
        ? ""
        : "WHERE ${whereClauses.join(" AND ")}";

    final res = await db.rawQuery('''
      SELECT m.*, 
        (SELECT GROUP_CONCAT(tg.name, ' ') FROM ${MetadataService.tableTags} tg JOIN $tableJunctionTags tj ON tg.id = tj.tag_id WHERE tj.meeting_id = m.id) as tag_list,
        (SELECT GROUP_CONCAT(p.name, ' ') FROM ${MetadataService.tableParticipants} p JOIN $tableJunctionParts pj ON p.id = pj.participant_id WHERE pj.meeting_id = m.id) as part_list
      FROM $tableMeetings m 
      $whereStr
      ORDER BY m.start_time ASC
    ''', args);
    return res.map(_mapToMeeting).toList();
  }

  Future<int> deleteMeeting(int id) async {
    final db = await _dbManager.database;
    return await db.transaction((txn) async {
      await txn.delete(
        tableJunctionTags,
        where: 'meeting_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        tableJunctionParts,
        where: 'meeting_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(tableMeetings, where: 'id = ?', whereArgs: [id]);
    });
  }

  MeetingModel _mapToMeeting(Map<String, dynamic> map) {
    final tags =
        (map['tag_list'] as String?)
            ?.split(' ')
            .where((t) => t.isNotEmpty)
            .toList() ??
        [];
    final parts =
        (map['part_list'] as String?)
            ?.split(' ')
            .where((p) => p.isNotEmpty)
            .toList() ??
        [];
    return MeetingModel.fromMap(map, tags: tags, participants: parts);
  }
}
