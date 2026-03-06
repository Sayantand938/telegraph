import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/meetings/services/meeting_database_service.dart';
import 'package:telegraph/features/meetings/services/meeting_command_handler.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('MeetingCommandHandler Extensive', () {
    late DatabaseManager dbManager;
    late MeetingDatabaseService dbService;
    late MeetingCommandHandler handler;
    final fixedTime = DateTime(2026, 3, 6, 14, 0);

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      final metadata = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadata.initializeTables(db);
      await db.execute(
        'CREATE TABLE meeting_sessions (id INTEGER PRIMARY KEY, start_time TEXT, end_time TEXT, notes TEXT)',
      );
      await db.execute(
        'CREATE TABLE meeting_session_tags (meeting_id INTEGER, tag_id INTEGER)',
      );
      await db.execute(
        'CREATE TABLE meeting_session_participants (meeting_id INTEGER, participant_id INTEGER)',
      );

      dbService = MeetingDatabaseService(
        dbManager: dbManager,
        metadataService: metadata,
      );
      handler = MeetingCommandHandler(dbService, clock: () => fixedTime);
    });

    tearDown(() async => await dbManager.close());

    test('should allow "meeting start" without a note', () async {
      final response = await handler.handle('meeting start @team #sync');
      expect(response, contains('✅ **Meeting Started**'));
      expect(response, contains('(no note)'));
      expect(response, contains('#sync'));
      expect(response, contains('@team'));
    });

    test('should handle "meeting stop" and return duration', () async {
      await handler.handle('meeting start "Design Sync"');
      final stopTime = fixedTime.add(const Duration(minutes: 30));
      final stopHandler = MeetingCommandHandler(
        dbService,
        clock: () => stopTime,
      );
      final response = await stopHandler.handle('meeting stop');
      expect(response, contains('✅ **Meeting Ended**'));
      expect(response, contains('"duration": "30m"'));
    });

    test('should reject overlapping meetings', () async {
      await handler.handle('meeting start "Meeting 1"');
      final response = await handler.handle('meeting start "Meeting 2"');
      expect(response, contains('🚨 **Error**'));
      expect(response, contains('Meeting already running'));
    });
  });
}
