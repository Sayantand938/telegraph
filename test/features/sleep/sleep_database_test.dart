import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/sleep/services/sleep_command_handler.dart';
import 'package:telegraph/features/sleep/services/sleep_database_service.dart';
import 'package:telegraph/features/sleep/sleep_module.dart';

void main() {
  late DatabaseManager dbManager;
  late MetadataService metadataService;
  late SleepDatabaseService sleepService;

  setUp(() async {
    // Initialize in-memory database for testing
    dbManager = DatabaseManager(dbPathOverride: ':memory:');
    metadataService = MetadataService(dbManager: dbManager);
    sleepService = SleepDatabaseService(
      dbManager: dbManager,
      metadataService: metadataService,
    );

    // ✅ Pass a real handler instance for the module setup
    final sleepModule = SleepModule(SleepCommandHandler(sleepService));

    await dbManager.initialize([...sleepModule.onCreateSql]);
    final db = await dbManager.database;
    await metadataService.initializeTables(db);
  });

  tearDown(() async {
    await dbManager.close();
  });

  group('SleepDatabaseService Tests', () {
    test('startSession creates an active session', () async {
      await sleepService.startSession('Falling asleep', [
        'bedtime',
      ], startTime: DateTime(2026, 3, 7, 22, 0));

      final active = await sleepService.getActiveSession();

      expect(active, isNotNull);
      expect(active!.notes, 'Falling asleep');
      expect(active.tags, contains('bedtime'));
      expect(active.endTime, isNull);
    });

    test(
      'stopSession completes an active session and handles splitting',
      () async {
        final start = DateTime(2026, 3, 7, 23, 0);
        final stop = DateTime(2026, 3, 8, 07, 0);

        await sleepService.startSession('Night sleep', [
          'deep',
        ], startTime: start);

        await sleepService.stopSession(stopTime: stop);

        final active = await sleepService.getActiveSession();
        expect(active, isNull);

        // Check for split sessions (one for March 7, one for March 8)
        final sessionsDay1 = await sleepService.getSessionsByDate(
          DateTime(2026, 3, 7),
        );
        final sessionsDay2 = await sleepService.getSessionsByDate(
          DateTime(2026, 3, 8),
        );

        expect(sessionsDay1.length, 1);
        expect(sessionsDay2.length, 1);
        expect(sessionsDay1.first.endTime, DateTime(2026, 3, 7, 23, 59, 59));
        expect(sessionsDay2.first.startTime, DateTime(2026, 3, 8, 0, 0, 0));
      },
    );

    test('recordCompletedSession logs a session directly', () async {
      final start = DateTime(2026, 3, 7, 14, 0);
      final end = DateTime(2026, 3, 7, 15, 30);

      await sleepService.recordCompletedSession(
        start: start,
        end: end,
        notes: 'Afternoon nap',
        tags: ['nap'],
      );

      final sessions = await sleepService.getSessionsByDate(
        DateTime(2026, 3, 7),
      );
      expect(sessions.length, 1);
      expect(sessions.first.notes, 'Afternoon nap');
      expect(sessions.first.tags, contains('nap'));
    });

    test('getSleepSummary calculates totals correctly', () async {
      final date = DateTime(2026, 3, 7);

      await sleepService.recordCompletedSession(
        start: DateTime(2026, 3, 7, 0, 0),
        end: DateTime(2026, 3, 7, 2, 0),
        notes: 'Session 1',
        tags: ['rest'],
      );

      await sleepService.recordCompletedSession(
        start: DateTime(2026, 3, 7, 10, 0),
        end: DateTime(2026, 3, 7, 11, 0),
        notes: 'Session 2',
        tags: ['rest'],
      );

      final summary = await sleepService.getSleepSummary(date: date);

      expect(summary.first['session_count'], 2);
      expect(summary.first['total_minutes'], 180.0);
      expect(summary.first['avg_minutes'], 90.0);
    });

    test('deleteSession removes record and junction entries', () async {
      await sleepService.recordCompletedSession(
        start: DateTime(2026, 3, 7, 1, 0),
        end: DateTime(2026, 3, 7, 2, 0),
        notes: 'To be deleted',
        tags: ['temp'],
      );

      final sessions = await sleepService.getSessionsByDate(
        DateTime(2026, 3, 7),
      );
      final id = sessions.first.id!;

      await sleepService.deleteSession(id);

      final sessionsAfter = await sleepService.getSessionsByDate(
        DateTime(2026, 3, 7),
      );
      expect(sessionsAfter, isEmpty);
    });
  });
}
