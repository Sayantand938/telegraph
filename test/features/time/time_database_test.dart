import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/time/services/time_database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TimeDatabaseService Extensive', () {
    late DatabaseManager dbManager;
    late MetadataService metadataService;
    late TimeDatabaseService timeDb;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadataService = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadataService.initializeTables(db);

      await db.execute('''CREATE TABLE IF NOT EXISTS time_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        notes TEXT
      )''');
      await db.execute('''CREATE TABLE IF NOT EXISTS time_session_tags (
        time_id INTEGER, tag_id INTEGER,
        PRIMARY KEY(time_id, tag_id),
        FOREIGN KEY(time_id) REFERENCES time_sessions(id),
        FOREIGN KEY(tag_id) REFERENCES tags(id)
      )''');

      timeDb = TimeDatabaseService(
        dbManager: dbManager,
        metadataService: metadataService,
      );
    });

    tearDown(() async => await dbManager.close());

    test('should record multi-day session as separate entries', () async {
      final start = DateTime(2026, 3, 5, 22, 0);
      final end = DateTime(2026, 3, 6, 2, 0);

      await timeDb.recordCompletedSession(
        start: start,
        end: end,
        notes: "Overnight coding",
        tags: ['dev'],
      );

      // ✅ Updated method calls
      final sessionsDay1 = await timeDb.getSessions(date: DateTime(2026, 3, 5));
      final sessionsDay2 = await timeDb.getSessions(date: DateTime(2026, 3, 6));

      expect(sessionsDay1.length, 1);
      expect(sessionsDay2.length, 1);
      expect(sessionsDay1.first.notes, "Overnight coding");
      expect(sessionsDay2.first.notes, "Overnight coding");
    });

    test('should aggregate tag-wise summary correctly', () async {
      final day = DateTime(2026, 3, 6);
      await timeDb.recordCompletedSession(
        start: DateTime(2026, 3, 6, 9, 0),
        end: DateTime(2026, 3, 6, 10, 0),
        notes: "Task 1",
        tags: ['work', 'code'],
      );
      await timeDb.recordCompletedSession(
        start: DateTime(2026, 3, 6, 11, 0),
        end: DateTime(2026, 3, 6, 11, 30),
        notes: "Task 2",
        tags: ['work'],
      );

      final summary = await timeDb.getTagWiseSummary(date: day);
      final workTag = summary.firstWhere((t) => t['tag'] == 'work');

      expect(workTag['total_minutes'], 90.0);
      expect(workTag['session_count'], 2);
    });

    test('should calculate hourly distribution', () async {
      final day = DateTime(2026, 3, 6);
      await timeDb.recordCompletedSession(
        start: DateTime(2026, 3, 6, 14, 0),
        end: DateTime(2026, 3, 6, 14, 45),
        notes: "Afternoon work",
        tags: [],
      );

      final hourly = await timeDb.getHourlyDistribution(date: day);
      expect(hourly[14]['total_minutes'], 45.0);
    });

    test('should delete session and all linked tags', () async {
      await timeDb.startSession('To be deleted', ['temp']);
      final active = await timeDb.getActiveSession();
      final id = active!.id!;

      await timeDb.deleteSession(id);
      final db = await dbManager.database;
      final sessionCheck = await db.query(
        'time_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      final tagCheck = await db.query(
        'time_session_tags',
        where: 'time_id = ?',
        whereArgs: [id],
      );

      expect(sessionCheck, isEmpty);
      expect(tagCheck, isEmpty);
    });
  });
}
