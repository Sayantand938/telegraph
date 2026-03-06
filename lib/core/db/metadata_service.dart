// lib/core/db/metadata_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/utils/logger.dart';

class MetadataService {
  final DatabaseManager _dbManager;

  MetadataService({required DatabaseManager dbManager})
    : _dbManager = dbManager;

  static const tableTags = 'tags';
  static const tableParticipants = 'participants';

  Future<void> initializeTables(Database db) async {
    try {
      // ✅ Added composite UNIQUE constraint to allow same name in different modules
      await db.execute('''
CREATE TABLE IF NOT EXISTS $tableTags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  module TEXT DEFAULT 'global',
  created_at TEXT DEFAULT (datetime('now')),
  last_used_at TEXT,
  UNIQUE(name, module)
)''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS $tableParticipants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  module TEXT DEFAULT 'global',
  created_at TEXT DEFAULT (datetime('now')),
  last_used_at TEXT,
  UNIQUE(name, module)
)''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tags_name ON $tableTags(name)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_participants_name ON $tableParticipants(name)',
      );

      Logger.db('Metadata tables initialized');
    } catch (e) {
      Logger.error('Metadata table initialization failed', tag: 'DB', err: e);
      rethrow;
    }
  }

  Future<int?> ensureTagExists(
    DatabaseExecutor txn,
    String tagName, {
    String? module,
  }) async {
    try {
      final name = tagName.toLowerCase().trim();
      if (name.isEmpty) throw ArgumentError('Tag name cannot be empty');
      final moduleName = module ?? 'global';

      final res = await txn.query(
        tableTags,
        where: 'name = ? AND module = ?',
        whereArgs: [name, moduleName],
      );

      if (res.isNotEmpty) {
        final id = res.first['id'] as int?;
        if (id != null) {
          await txn.update(
            tableTags,
            {'last_used_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [id],
          );
          return id;
        }
      }

      return await txn.insert(tableTags, {
        'name': name,
        'module': moduleName,
        'created_at': DateTime.now().toIso8601String(),
        'last_used_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error('ensureTagExists failed for "$tagName"', tag: 'DB', err: e);
      return null;
    }
  }

  Future<int?> ensureParticipantExists(
    DatabaseExecutor txn,
    String participantName, {
    String? module,
  }) async {
    try {
      final name = participantName.toLowerCase().trim();
      if (name.isEmpty) throw ArgumentError('Participant name cannot be empty');
      final moduleName = module ?? 'global';

      final res = await txn.query(
        tableParticipants,
        where: 'name = ? AND module = ?',
        whereArgs: [name, moduleName],
      );

      if (res.isNotEmpty) {
        final id = res.first['id'] as int?;
        if (id != null) {
          await txn.update(
            tableParticipants,
            {'last_used_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [id],
          );
          return id;
        }
      }

      return await txn.insert(tableParticipants, {
        'name': name,
        'module': moduleName,
        'created_at': DateTime.now().toIso8601String(),
        'last_used_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error(
        'ensureParticipantExists failed for "$participantName"',
        tag: 'DB',
        err: e,
      );
      return null;
    }
  }

  Future<void> linkEntityToTag(
    DatabaseExecutor txn,
    String junctionTable,
    String entityIdColumn,
    int entityId,
    String tagName, {
    String? module,
  }) async {
    try {
      if (entityId <= 0) return;
      final tagId = await ensureTagExists(txn, tagName, module: module);
      if (tagId == null) return;
      await txn.insert(junctionTable, {
        entityIdColumn: entityId,
        'tag_id': tagId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      Logger.error('linkEntityToTag failed', tag: 'DB', err: e);
    }
  }

  Future<void> linkEntityToParticipant(
    DatabaseExecutor txn,
    String junctionTable,
    String entityIdColumn,
    int entityId,
    String participantName, {
    String? module,
  }) async {
    try {
      if (entityId <= 0) return;
      final partId = await ensureParticipantExists(
        txn,
        participantName,
        module: module,
      );
      if (partId == null) return;
      await txn.insert(junctionTable, {
        entityIdColumn: entityId,
        'participant_id': partId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      Logger.error('linkEntityToParticipant failed', tag: 'DB', err: e);
    }
  }

  Future<void> linkEntityToTags(
    DatabaseExecutor txn,
    String junctionTable,
    String entityIdColumn,
    int entityId,
    List<String> tagNames, {
    String? module,
  }) async {
    for (final tag in tagNames) {
      await linkEntityToTag(
        txn,
        junctionTable,
        entityIdColumn,
        entityId,
        tag,
        module: module,
      );
    }
  }

  Future<void> linkEntityToParticipants(
    DatabaseExecutor txn,
    String junctionTable,
    String entityIdColumn,
    int entityId,
    List<String> participantNames, {
    String? module,
  }) async {
    for (final participant in participantNames) {
      await linkEntityToParticipant(
        txn,
        junctionTable,
        entityIdColumn,
        entityId,
        participant,
        module: module,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAllTags({String? module}) async {
    try {
      final db = await _dbManager.database;
      final where = module != null ? 'module = ?' : null;
      final whereArgs = module != null ? [module] : null;
      return await db.query(
        tableTags,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'last_used_at DESC',
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllParticipants({
    String? module,
  }) async {
    try {
      final db = await _dbManager.database;
      final where = module != null ? 'module = ?' : null;
      final whereArgs = module != null ? [module] : null;
      return await db.query(
        tableParticipants,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'last_used_at DESC',
      );
    } catch (e) {
      return [];
    }
  }
}
