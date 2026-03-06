import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/db/database_manager.dart';
import 'package:telegraph/core/db/metadata_service.dart';
import 'package:telegraph/features/meetings/services/meeting_database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('MeetingDatabaseService Extensive', () {
    late DatabaseManager dbManager;
    late MetadataService metadataService;
    late MeetingDatabaseService meetingDb;

    setUp(() async {
      dbManager = DatabaseManager(dbPathOverride: ':memory:');
      metadataService = MetadataService(dbManager: dbManager);
      final db = await dbManager.database;
      await metadataService.initializeTables(db);

      await db.execute('''CREATE TABLE meeting_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        notes TEXT
      )''');
      await db.execute('''CREATE TABLE meeting_session_tags (
        meeting_id INTEGER, tag_id INTEGER,
        PRIMARY KEY(meeting_id, tag_id),
        FOREIGN KEY(meeting_id) REFERENCES meeting_sessions(id),
        FOREIGN KEY(tag_id) REFERENCES tags(id)
      )''');
      await db.execute('''CREATE TABLE meeting_session_participants (
        meeting_id INTEGER, participant_id INTEGER,
        PRIMARY KEY(meeting_id, participant_id),
        FOREIGN KEY(meeting_id) REFERENCES meeting_sessions(id),
        FOREIGN KEY(participant_id) REFERENCES participants(id)
      )''');

      meetingDb = MeetingDatabaseService(
        dbManager: dbManager,
        metadataService: metadataService,
      );
    });

    tearDown(() async => await dbManager.close());

    test(
      'should start a meeting and correctly link participants/tags',
      () async {
        await meetingDb.startMeeting(
          'Sprint Planning',
          ['agile', 'dev'],
          ['scrum_master', 'developers'],
        );

        final active = await meetingDb.getActiveMeeting();
        expect(active, isNotNull);
        expect(
          active!.displayParticipants,
          containsAll(['@scrum_master', '@developers']),
        );
        expect(active.displayTags, containsAll(['#agile', '#dev']));
      },
    );

    test('should split a meeting correctly across midnight', () async {
      final start = DateTime(2026, 3, 5, 23, 30);
      final end = DateTime(2026, 3, 6, 1, 30);

      await meetingDb.recordCompletedMeeting(
        start: start,
        end: end,
        notes: "Global Sync",
        tags: ['remote'],
        participants: ['intl_team'],
      );

      // ✅ Updated method call
      final day1 = await meetingDb.getMeetings(date: DateTime(2026, 3, 5));
      final day2 = await meetingDb.getMeetings(date: DateTime(2026, 3, 6));

      expect(day1.length, 1);
      expect(day2.length, 1);
      expect(day1.first.notes, "Global Sync");
      expect(day2.first.notes, "Global Sync");
      expect(day1.first.participants, contains('intl_team'));
      expect(day2.first.participants, contains('intl_team'));
    });

    test('should verify junction table cleanup on delete', () async {
      await meetingDb.startMeeting('Temporary Meeting', ['temp'], ['nobody']);
      final active = await meetingDb.getActiveMeeting();
      final id = active!.id!;

      await meetingDb.deleteMeeting(id);

      final db = await dbManager.database;
      final tagLinks = await db.query(
        'meeting_session_tags',
        where: 'meeting_id = ?',
        whereArgs: [id],
      );
      final partLinks = await db.query(
        'meeting_session_participants',
        where: 'meeting_id = ?',
        whereArgs: [id],
      );

      expect(tagLinks, isEmpty);
      expect(partLinks, isEmpty);
    });

    test(
      'should handle multiple participants and ensure global uniqueness',
      () async {
        await meetingDb.startMeeting('M1', [], ['charlie']);
        await meetingDb.stopActiveMeeting();
        await meetingDb.startMeeting('M2', [], ['charlie']);
        await meetingDb.stopActiveMeeting();

        final db = await dbManager.database;
        final charlieCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM participants WHERE name = ?',
            ['charlie'],
          ),
        );

        expect(charlieCount, 1);
      },
    );
  });
}
