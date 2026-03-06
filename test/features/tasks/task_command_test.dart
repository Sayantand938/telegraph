import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/tasks/services/task_database_service.dart';
import 'package:telegraph/features/tasks/services/task_command_handler.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TaskCommandHandler Extensive', () {
    late DatabaseManager dbManager;
    late TaskDatabaseService dbService;
    late TaskCommandHandler handler;
    final fixedTime = DateTime(2026, 3, 6, 12, 0);

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      final metadata = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadata.initializeTables(db);
      await db.execute(
        'CREATE TABLE task_items (id INTEGER PRIMARY KEY, notes TEXT, is_completed INTEGER, created_at TEXT, due_date TEXT, completed_at TEXT)',
      );
      await db.execute(
        'CREATE TABLE task_tag_junction (task_id INTEGER, tag_id INTEGER)',
      );
      await db.execute(
        'CREATE TABLE task_participant_junction (task_id INTEGER, participant_id INTEGER)',
      );

      dbService = TaskDatabaseService(
        dbManager: dbManager,
        metadataService: metadata,
      );
      handler = TaskCommandHandler(dbService, clock: () => fixedTime);
    });

    tearDown(() async => await dbManager.close());

    test('should allow "task add" without note', () async {
      final response = await handler.handle('task add #work');
      expect(response, contains('✅ **Task Added**'));
      expect(response, contains('(no note)'));
      expect(response, contains('#work'));
    });

    test('should mark task as done', () async {
      await handler.handle('task add "Buy Milk"');
      final response = await handler.handle('task done 1');
      expect(response, contains('✅ **Task Done**'));
      expect(response, contains('"id": 1'));
    });
  });
}
