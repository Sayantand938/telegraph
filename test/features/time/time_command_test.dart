import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/time/services/time_database_service.dart';
import 'package:telegraph/features/time/services/time_command_handler.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TimeCommandHandler Extensive', () {
    late DatabaseManager dbManager;
    late TimeDatabaseService dbService;
    late TimeCommandHandler handler;
    final fixedTime = DateTime(2026, 3, 6, 12, 0);

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      final metadata = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadata.initializeTables(db);
      await db.execute(
        'CREATE TABLE time_sessions (id INTEGER PRIMARY KEY, start_time TEXT, end_time TEXT, notes TEXT)',
      );
      await db.execute(
        'CREATE TABLE time_session_tags (time_id INTEGER, tag_id INTEGER)',
      );

      dbService = TimeDatabaseService(
        dbManager: dbManager,
        metadataService: metadata,
      );
      handler = TimeCommandHandler(dbService, clock: () => fixedTime);
    });

    tearDown(() async => await dbManager.close());

    test('should handle "time stop" and return correct duration', () async {
      await handler.handle('time start "Deep Work"');
      final fortyFiveMinsLater = fixedTime.add(const Duration(minutes: 45));
      final stopHandler = TimeCommandHandler(
        dbService,
        clock: () => fortyFiveMinsLater,
      );
      final response = await stopHandler.handle('time stop');
      expect(response, contains('✅ **Session Stopped**'));
      expect(response, contains('"duration": "45m"'));
    });

    test('should handle "time log yesterday" with range', () async {
      final response = await handler.handle(
        'time log yesterday 09:00-11:00 "Deep Work" #focus',
      );
      expect(response, contains('✅ **Logged**'));
      expect(response, contains('"duration": "2h 0m"'));

      // ✅ Updated method call
      final sessions = await dbService.getSessions(date: DateTime(2026, 3, 5));
      expect(sessions.length, 1);
      expect(sessions.first.notes, "Deep Work");
    });

    test('should handle "time log" with duration', () async {
      final response = await handler.handle('time log 1.5h "Coding Session"');
      expect(response, contains('✅ **Logged**'));
      expect(response, contains('"duration": "1h 30m"'));
      expect(response, contains('"period": "10:30-12:00"'));
    });

    test('should allow "time log" without a note', () async {
      final response = await handler.handle('time log 09:00-10:00 #tag');
      expect(response, contains('✅ **Logged**'));
      expect(response, contains('(no note)'));
    });

    test('should handle "time status" correctly', () async {
      await handler.handle('time start "Coding"');
      final response = await handler.handle('time status');
      expect(response, contains('🕒 **Tracking**'));
      expect(response, contains('Coding'));
    });

    test('should generate a summary report', () async {
      await handler.handle('time log today 08:00-10:00 "Work" #job');
      final response = await handler.handle('time summary');
      expect(response, contains('📊 **Summary Report**'));
      expect(response, contains('"total_time": "2h 0m"'));
    });

    test('should reject invalid time formats', () async {
      final response = await handler.handle('time log 9am-10am "Bad format"');
      expect(response, contains('🚨 **Error**'));
      expect(response, contains('HH:mm-HH:mm'));
    });
  });
}
