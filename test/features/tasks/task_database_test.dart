import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/tasks/services/task_database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TaskDatabaseService Extensive', () {
    late DatabaseManager dbManager;
    late MetadataService metadataService;
    late TaskDatabaseService taskDb;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadataService = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadataService.initializeTables(db);

      await db.execute('''CREATE TABLE task_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notes TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        due_date TEXT,
        completed_at TEXT
      )''');
      await db.execute('''CREATE TABLE task_tag_junction (
        task_id INTEGER, tag_id INTEGER,
        PRIMARY KEY(task_id, tag_id),
        FOREIGN KEY(task_id) REFERENCES task_items(id),
        FOREIGN KEY(tag_id) REFERENCES tags(id)
      )''');
      await db.execute('''CREATE TABLE task_participant_junction (
        task_id INTEGER, participant_id INTEGER,
        PRIMARY KEY(task_id, participant_id),
        FOREIGN KEY(task_id) REFERENCES task_items(id),
        FOREIGN KEY(participant_id) REFERENCES participants(id)
      )''');

      taskDb = TaskDatabaseService(
        dbManager: dbManager,
        metadataService: metadataService,
      );
    });

    tearDown(() async => await dbManager.close());

    test('should add task and correctly link metadata', () async {
      await taskDb.addTask(
        'Setup CI/CD',
        ['devops', 'automation'],
        ['team_lead'],
      );

      final tasks = await taskDb.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.displayTags, containsAll(['#devops', '#automation']));
      expect(tasks.first.displayParticipants, contains('@team_lead'));
    });

    test('should mark task as completed and record timestamp', () async {
      await taskDb.addTask('Unfinished task', [], []);
      final id = (await taskDb.getTasks()).first.id!;

      await taskDb.markAsDone(id);

      final tasks = await taskDb.getTasks(includeCompleted: true);
      expect(tasks.first.isCompleted, isTrue);
      expect(tasks.first.completedAt, isNotNull);
    });

    test('should verify junction table cleanup on task deletion', () async {
      await taskDb.addTask('Cleanup test', ['temp'], ['nobody']);
      final id = (await taskDb.getTasks()).first.id!;

      await taskDb.deleteTask(id);

      final db = await dbManager.database;
      final tagLinks = await db.query(
        'task_tag_junction',
        where: 'task_id = ?',
        whereArgs: [id],
      );
      final partLinks = await db.query(
        'task_participant_junction',
        where: 'task_id = ?',
        whereArgs: [id],
      );

      expect(tagLinks, isEmpty);
      expect(partLinks, isEmpty);
    });

    test('should ensure metadata global uniqueness', () async {
      // Add two tasks with the same participant
      await taskDb.addTask('T1', [], ['manager']);
      await taskDb.addTask('T2', [], ['manager']);

      final db = await dbManager.database;
      final managerCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM participants WHERE name = ?', [
          'manager',
        ]),
      );

      // Participant "manager" should only exist once
      expect(managerCount, 1);
    });
  });
}
