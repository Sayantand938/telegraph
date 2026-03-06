import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/core/db/metadata_mixin.dart';
import 'package:telegraph/features/tasks/models/task_model.dart';

class TaskDatabaseService with MetadataMixin {
  final DatabaseManager _dbManager;
  @override
  final MetadataService metadataService;

  TaskDatabaseService({
    required DatabaseManager dbManager,
    required this.metadataService,
  }) : _dbManager = dbManager;

  static const tableTasks = 'task_items';
  static const tableJunctionTags = 'task_tag_junction';
  static const tableJunctionParts = 'task_participant_junction';

  Future<void> addTask(
    String notes,
    List<String> tags,
    List<String> participants, {
    DateTime? dueDate,
    bool isCompleted = false,
    DateTime? createdAt,
  }) async {
    final db = await _dbManager.database;
    final now = createdAt ?? DateTime.now();
    await db.transaction((txn) async {
      final id = await txn.insert(tableTasks, {
        'notes': notes,
        'created_at': now.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? now.toIso8601String() : null,
      });
      await metadataService.linkEntityToTags(
        txn,
        tableJunctionTags,
        'task_id',
        id,
        tags,
        module: 'task',
      );
      await metadataService.linkEntityToParticipants(
        txn,
        tableJunctionParts,
        'task_id',
        id,
        participants,
        module: 'task',
      );
    });
  }

  /// ✅ Fixed: Added filtering by tag and participant
  Future<List<TaskModel>> getTasks({
    bool includeCompleted = false,
    String? tag,
    String? participant,
  }) async {
    final db = await _dbManager.database;
    List<String> whereClauses = [];
    List<dynamic> args = [];

    if (!includeCompleted) {
      whereClauses.add("t.is_completed = 0");
    }
    if (tag != null) {
      whereClauses.add(
        "t.id IN (SELECT task_id FROM $tableJunctionTags tj JOIN ${MetadataService.tableTags} tg ON tj.tag_id = tg.id WHERE tg.name = ?)",
      );
      args.add(tag.toLowerCase().trim());
    }
    if (participant != null) {
      whereClauses.add(
        "t.id IN (SELECT task_id FROM $tableJunctionParts pj JOIN ${MetadataService.tableParticipants} p ON pj.participant_id = p.id WHERE p.name = ?)",
      );
      args.add(participant.toLowerCase().trim());
    }

    final whereStr = whereClauses.isEmpty
        ? ""
        : "WHERE ${whereClauses.join(" AND ")}";

    final res = await db.rawQuery('''
      SELECT t.*,
        (SELECT GROUP_CONCAT(tg.name, ' ') FROM ${MetadataService.tableTags} tg JOIN $tableJunctionTags tj ON tg.id = tj.tag_id WHERE tj.task_id = t.id) as tag_list,
        (SELECT GROUP_CONCAT(p.name, ' ') FROM ${MetadataService.tableParticipants} p JOIN $tableJunctionParts pj ON p.id = pj.participant_id WHERE pj.task_id = t.id) as part_list
      FROM $tableTasks t
      $whereStr
      ORDER BY t.is_completed ASC, t.created_at DESC
    ''', args);

    return res.map((m) {
      final tags =
          (m['tag_list'] as String?)
              ?.split(' ')
              .where((t) => t.isNotEmpty)
              .toList() ??
          [];
      final parts =
          (m['part_list'] as String?)
              ?.split(' ')
              .where((p) => p.isNotEmpty)
              .toList() ??
          [];
      return TaskModel.fromMap(m, tags: tags, participants: parts);
    }).toList();
  }

  Future<int> markAsDone(int id) async {
    final db = await _dbManager.database;
    return await db.update(
      tableTasks,
      {'is_completed': 1, 'completed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await _dbManager.database;
    return await db.transaction((txn) async {
      await txn.delete(
        tableJunctionTags,
        where: 'task_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        tableJunctionParts,
        where: 'task_id = ?',
        whereArgs: [id],
      );
      return await txn.delete(tableTasks, where: 'id = ?', whereArgs: [id]);
    });
  }
}
