import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/sleep/services/sleep_database_service.dart';
import 'package:telegraph/features/sleep/services/sleep_command_handler.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SleepCommandHandler Refactored', () {
    late DatabaseManager dbManager;
    late SleepDatabaseService dbService;
    late SleepCommandHandler handler;
    final fixedTime = DateTime(2026, 3, 6, 23, 0);

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      final metadata = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadata.initializeTables(db);

      // ✅ Removed quality_rating and interruptions columns
      await db.execute(
        'CREATE TABLE sleep_sessions (id INTEGER PRIMARY KEY, start_time TEXT, end_time TEXT, notes TEXT)',
      );
      await db.execute(
        'CREATE TABLE sleep_session_tags (sleep_id INTEGER, tag_id INTEGER)',
      );

      dbService = SleepDatabaseService(
        dbManager: dbManager,
        metadataService: metadata,
      );
      handler = SleepCommandHandler(dbService, clock: () => fixedTime);
    });

    tearDown(() async => await dbManager.close());

    test('should handle "sleep start" with formatted tags', () async {
      final response = await handler.handle('sleep start #recovery');
      expect(response, contains('✅ **Sleep Tracking Started**'));
      expect(response, contains('#recovery'));
    });

    test('should handle "sleep list" with pretty duration', () async {
      await handler.handle('sleep log yesterday 22:00-06:00 "Sleep"');
      final response = await handler.handle('sleep list yesterday');
      expect(response, contains('📅 **Sleep Sessions: 2026-03-05**'));
      // Verifying duration formatting (crossover segment)
      expect(response, contains('"duration": "1h 59m"'));
    });

    test('should handle "sleep status" for active session', () async {
      await handler.handle('sleep start "Nightly"');
      final response = await handler.handle('sleep status');
      expect(response, contains('🛏️ **Tracking Sleep**'));
      expect(response, contains('Nightly'));
    });
  });
}
