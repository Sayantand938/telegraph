import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/models/session.dart';
import '../../fixtures/sample_data.dart';

void main() {
  group('Session Model', () {
    group('Constructor', () {
      test('creates instance with required fields', () {
        final session = SessionFixtures.activeSession();
        expect(session.startTime, isNotNull);
        expect(session.endTime, isNull);
        expect(session.notes, isNotNull);
      });

      test('creates instance with all fields', () {
        final session = SessionFixtures.completedSession();
        expect(session.id, isNull);
        expect(session.startTime, isNotNull);
        expect(session.endTime, isNotNull);
        expect(session.notes, isNotNull);
      });
    });

    group('toJson', () {
      test('converts session to json correctly', () {
        final session = SessionFixtures.validSession(
          id: 1,
          startTime: '2025-01-15T10:30:00Z',
          endTime: '2025-01-15T17:30:00Z',
          notes: 'Test notes',
        );
        final json = session.toJson();

        expect(json['id'], 1);
        expect(json['start_time'], '2025-01-15T10:30:00Z');
        expect(json['end_time'], '2025-01-15T17:30:00Z');
        expect(json['notes'], 'Test notes');
      });

      test('handles null id', () {
        final session = SessionFixtures.activeSession();
        final json = session.toJson();

        expect(json['id'], isNull);
      });

      test('handles null endTime', () {
        final session = SessionFixtures.activeSession();
        final json = session.toJson();

        expect(json['end_time'], isNull);
      });

      test('handles null notes', () {
        final session = SessionFixtures.validSession(notes: null);
        final json = session.toJson();

        expect(json['notes'], isNull);
      });
    });

    group('fromJson', () {
      test('creates session from json correctly', () {
        final json = SessionFixtures.toMapFixture(
          id: 1,
          startTime: '2025-01-15T10:30:00Z',
          endTime: '2025-01-15T17:30:00Z',
          notes: 'Test notes',
        );
        final session = Session.fromJson(json);

        expect(session.id, 1);
        expect(session.startTime, '2025-01-15T10:30:00Z');
        expect(session.endTime, '2025-01-15T17:30:00Z');
        expect(session.notes, 'Test notes');
      });

      test('handles null endTime', () {
        final json = SessionFixtures.toMapFixture(
          startTime: '2025-01-15T10:30:00Z',
          endTime: null,
          notes: 'Active session',
        );
        final session = Session.fromJson(json);

        expect(session.endTime, isNull);
      });

      test('handles null notes', () {
        final json = SessionFixtures.toMapFixture(
          startTime: '2025-01-15T10:30:00Z',
          notes: null,
        );
        final session = Session.fromJson(json);

        expect(session.notes, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with all fields', () {
        final original = SessionFixtures.activeSession();
        final copy = original.copyWith(id: 1, notes: 'Updated notes');

        expect(copy.id, 1);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
        expect(copy.notes, 'Updated notes');
      });

      test('preserves original when no parameters provided', () {
        final original = SessionFixtures.activeSession();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
        expect(copy.notes, original.notes);
      });

      test('updates only specified fields', () {
        final original = SessionFixtures.completedSession();
        final copy = original.copyWith(notes: 'Updated notes');

        expect(copy.id, original.id);
        expect(copy.startTime, original.startTime);
        expect(copy.endTime, original.endTime);
        expect(copy.notes, 'Updated notes');
      });
    });

    group('Equality', () {
      test('two sessions with same data are equal', () {
        final session1 = SessionFixtures.validSession(
          id: 1,
          startTime: '2025-01-15T10:30:00Z',
          endTime: '2025-01-15T17:30:00Z',
          notes: 'Test',
        );
        final session2 = Session(
          id: 1,
          startTime: '2025-01-15T10:30:00Z',
          endTime: '2025-01-15T17:30:00Z',
          notes: 'Test',
        );

        expect(session1, equals(session2));
      });

      test('sessions with different data are not equal', () {
        final session1 = SessionFixtures.activeSession();
        final session2 = SessionFixtures.completedSession();

        expect(session1, isNot(equals(session2)));
      });
    });
  });
}
