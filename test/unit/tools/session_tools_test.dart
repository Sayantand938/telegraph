import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:telegraph/services/tools/session_tools.dart';
import 'package:telegraph/services/tools/tool_definitions.dart';
import 'package:telegraph/services/repositories/i_session_repository.dart';
import 'package:telegraph/models/session.dart';
import 'package:telegraph/core/errors/exceptions.dart';
import 'package:telegraph/core/errors/result.dart';
import 'package:telegraph/services/database/i_session_database.dart';
import '../../fixtures/sample_data.dart';
import '../../fixtures/mocks.dart';

void main() {
  late MockSessionRepository mockSessionRepo;
  late List<Tool> sessionTools;

  setUpAll(() {
    registerFallbackValue(
      Session(id: 0, startTime: '', endTime: null, notes: null),
    );
    registerFallbackValue(DateTime(2025, 1, 1));
  });

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    sessionTools = getSessionTools(mockSessionRepo);
  });

  group('Session Tools', () {
    group('start_session', () {
      test('returns success message when session created', () async {
        // Arrange
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNull(),
        ).thenAnswer((_) async => Result.success([]));
        when(
          () => mockSessionRepo.hasOverlap(any(), any()),
        ).thenAnswer((_) async => Result.success(false));
        when(
          () => mockSessionRepo.createSession(
            notes: any(named: 'notes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => Result.success(1));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'start_session')
            .execute({'notes': 'Test session'});

        // Assert
        expect(result, contains('Session started with ID: 1'));
      });

      test('validates start_time format', () async {
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'start_session')
              .execute({'start_time': 'invalid-date'}),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'INVALID_DATE_FORMAT',
            ),
          ),
        );
      });

      test('validates end_time format when provided', () async {
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'start_session')
              .execute({'end_time': 'invalid-date'}),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'INVALID_DATE_FORMAT',
            ),
          ),
        );
      });

      test('prevents starting session when active session exists', () async {
        // Arrange
        when(() => mockSessionRepo.getSessionsByEndTimeIsNull()).thenAnswer(
          (_) async => Result.success([SessionFixtures.activeSession()]),
        );

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'start_session')
              .execute({}),
          throwsA(
            isA<BusinessLogicException>().having(
              (e) => e.code,
              'code',
              'ACTIVE_SESSION_EXISTS',
            ),
          ),
        );
      });

      test('prevents starting session when time overlap detected', () async {
        // Arrange
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNull(),
        ).thenAnswer((_) async => Result.success([]));
        when(
          () => mockSessionRepo.hasOverlap(any(), any()),
        ).thenAnswer((_) async => Result.success(true));

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'start_session')
              .execute({}),
          throwsA(
            isA<BusinessLogicException>().having(
              (e) => e.code,
              'code',
              'SESSION_OVERLAP',
            ),
          ),
        );
      });

      test('handles database failure in createSession', () async {
        // Arrange
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNull(),
        ).thenAnswer((_) async => Result.success([]));
        when(
          () => mockSessionRepo.hasOverlap(any(), any()),
        ).thenAnswer((_) async => Result.success(false));
        when(
          () => mockSessionRepo.createSession(
            notes: any(named: 'notes'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer(
          (_) async =>
              Result.failure(DatabaseException('DB error', code: 'DB_ERROR')),
        );

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'start_session')
              .execute({'notes': 'Test session'}),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('end_session', () {
      test('returns success message when active session ended', () async {
        // Arrange
        final activeSession = SessionFixtures.activeSession().copyWith(id: 1);
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNull(),
        ).thenAnswer((_) async => Result.success([activeSession]));
        when(
          () => mockSessionRepo.endActiveSession(notes: any(named: 'notes')),
        ).thenAnswer(
          (_) async => Result.success(
            EndSessionResult(
              originalSessionId: 1,
              finalSessionId: 1,
              totalSessionsCreated: 1,
              splitOccurred: false,
            ),
          ),
        );

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'end_session')
            .execute({'notes': 'Ending session'});

        // Assert
        expect(result, contains('Active session ended successfully'));
      });

      test('throws NotFoundException when no active session found', () async {
        // Arrange
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNull(),
        ).thenAnswer((_) async => Result.success([]));
        when(
          () => mockSessionRepo.endActiveSession(notes: any(named: 'notes')),
        ).thenAnswer((_) async => Result.success(null));

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'end_session')
              .execute({}),
          throwsA(
            isA<NotFoundException>().having(
              (e) => e.code,
              'code',
              'NO_ACTIVE_SESSION',
            ),
          ),
        );
      });

      test('handles session splitting across midnight', () async {
        // Arrange
        final multiDaySession = SessionFixtures.multiDaySession().copyWith(
          id: 1,
        );
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNull(),
        ).thenAnswer((_) async => Result.success([multiDaySession]));
        when(
          () => mockSessionRepo.endActiveSession(notes: any(named: 'notes')),
        ).thenAnswer(
          (_) async => Result.success(
            EndSessionResult(
              originalSessionId: 1,
              finalSessionId: 3,
              totalSessionsCreated: 3,
              splitOccurred: true,
            ),
          ),
        );

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'end_session')
            .execute({});

        // Assert
        expect(result, contains('split into 3 daily sessions'));
      });
    });

    group('list_sessions', () {
      test('lists all sessions when no filter applied', () async {
        // Arrange
        final sessions = [
          SessionFixtures.activeSession().copyWith(id: 1),
          SessionFixtures.completedSession().copyWith(id: 2),
        ];
        when(
          () => mockSessionRepo.getAllSessions(),
        ).thenAnswer((_) async => Result.success(sessions));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'list_sessions')
            .execute({});

        // Assert
        expect(result, contains('Sessions:'));
        expect(result, contains('ID: 1'));
        expect(result, contains('ID: 2'));
      });

      test('filters active sessions when status=active', () async {
        // Arrange
        final sessions = [
          SessionFixtures.activeSession().copyWith(id: 1),
          SessionFixtures.completedSession().copyWith(id: 2),
        ];
        // Only active sessions should be returned by getSessionsByEndTimeIsNull
        final activeSessions = sessions
            .where((s) => s.endTime == null)
            .toList();
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNull(),
        ).thenAnswer((_) async => Result.success(activeSessions));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'list_sessions')
            .execute({'status': 'active'});

        // Assert
        expect(result, contains('ID: 1'));
        expect(result, isNot(contains('ID: 2')));
      });

      test('filters completed sessions when status=completed', () async {
        // Arrange
        final sessions = [
          SessionFixtures.activeSession().copyWith(id: 1),
          SessionFixtures.completedSession().copyWith(id: 2),
        ];
        // Only completed sessions should be returned by getSessionsByEndTimeIsNotNull
        final completedSessions = sessions
            .where((s) => s.endTime != null)
            .toList();
        when(
          () => mockSessionRepo.getSessionsByEndTimeIsNotNull(),
        ).thenAnswer((_) async => Result.success(completedSessions));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'list_sessions')
            .execute({'status': 'completed'});

        // Assert
        expect(result, contains('ID: 2'));
        expect(result, isNot(contains('ID: 1')));
      });

      test('returns "No sessions found" when empty', () async {
        // Arrange
        when(
          () => mockSessionRepo.getAllSessions(),
        ).thenAnswer((_) async => Result.success([]));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'list_sessions')
            .execute({});

        // Assert
        expect(result, contains('No sessions found'));
      });
    });

    group('get_session', () {
      test('returns session details when found', () async {
        // Arrange
        final session = SessionFixtures.completedSession().copyWith(id: 1);
        when(
          () => mockSessionRepo.getSession(1),
        ).thenAnswer((_) async => Result.success(session));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'get_session')
            .execute({'session_id': 1});

        // Assert
        expect(result, contains('Session 1:'));
        expect(result, contains('Start:'));
        expect(result, contains('End:'));
      });

      test('throws NotFoundException when session does not exist', () async {
        // Arrange
        when(
          () => mockSessionRepo.getSession(999),
        ).thenAnswer((_) async => Result.success(null));

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'get_session')
              .execute({'session_id': 999}),
          throwsA(
            isA<NotFoundException>().having(
              (e) => e.code,
              'code',
              'SESSION_NOT_FOUND',
            ),
          ),
        );
      });
    });

    group('delete_session', () {
      test('returns success message when session deleted', () async {
        // Arrange
        when(
          () => mockSessionRepo.deleteSession(1),
        ).thenAnswer((_) async => Result.success(1));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'delete_session')
            .execute({'session_id': 1});

        // Assert
        expect(result, contains('Session 1 deleted successfully'));
      });

      test('throws NotFoundException when session does not exist', () async {
        // Arrange
        when(
          () => mockSessionRepo.deleteSession(999),
        ).thenAnswer((_) async => Result.success(0));

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'delete_session')
              .execute({'session_id': 999}),
          throwsA(
            isA<NotFoundException>().having(
              (e) => e.code,
              'code',
              'SESSION_NOT_FOUND',
            ),
          ),
        );
      });
    });

    group('get_active_session', () {
      test('returns most recent active session', () async {
        // Arrange
        final sessions = [
          SessionFixtures.activeSession().copyWith(
            id: 1,
            startTime: '2025-01-15T09:00:00Z',
          ),
          SessionFixtures.activeSession().copyWith(
            id: 2,
            startTime: '2025-01-15T10:00:00Z',
          ),
        ];
        when(() => mockSessionRepo.getMostRecentActiveSession()).thenAnswer(
          (_) async => Result.success(sessions[1]),
        ); // Most recent (ID 2)

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'get_active_session')
            .execute({});

        // Assert
        expect(result, contains('Active Session ID: 2'));
      });

      test('throws NotFoundException when no active session exists', () async {
        // Arrange
        when(
          () => mockSessionRepo.getMostRecentActiveSession(),
        ).thenAnswer((_) async => Result.success(null));

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'get_active_session')
              .execute({}),
          throwsA(
            isA<NotFoundException>().having(
              (e) => e.code,
              'code',
              'NO_ACTIVE_SESSION',
            ),
          ),
        );
      });
    });

    group('update_session_notes', () {
      test('adds notes to session successfully', () async {
        // Arrange
        final session = SessionFixtures.activeSession().copyWith(
          id: 1,
          notes: null,
        );
        when(
          () => mockSessionRepo.getSession(1),
        ).thenAnswer((_) async => Result.success(session));
        when(
          () => mockSessionRepo.updateSession(any()),
        ).thenAnswer((_) async => Result.success(1));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'update_session_notes')
            .execute({'session_id': 1, 'notes': 'New notes'});

        // Assert
        expect(result, contains('Session 1 notes updated successfully'));
      });

      test('appends notes when append=true and existing notes exist', () async {
        // Arrange
        final session = SessionFixtures.activeSession().copyWith(
          id: 1,
          notes: 'Original',
        );
        when(
          () => mockSessionRepo.getSession(1),
        ).thenAnswer((_) async => Result.success(session));
        when(
          () => mockSessionRepo.updateSession(any()),
        ).thenAnswer((_) async => Result.success(1));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'update_session_notes')
            .execute({'session_id': 1, 'notes': 'Added later', 'append': true});

        // Assert
        expect(result, contains('Current notes:'));
        expect(result, contains('Original'));
        expect(result, contains('Added later'));
      });

      test('overwrites notes when append=false', () async {
        // Arrange
        final session = SessionFixtures.activeSession().copyWith(
          id: 1,
          notes: 'Original',
        );
        when(
          () => mockSessionRepo.getSession(1),
        ).thenAnswer((_) async => Result.success(session));
        when(
          () => mockSessionRepo.updateSession(any()),
        ).thenAnswer((_) async => Result.success(1));

        // Act
        final result = await sessionTools
            .firstWhere((t) => t.name == 'update_session_notes')
            .execute({'session_id': 1, 'notes': 'New notes', 'append': false});

        // Assert
        expect(result, contains('Current notes:'));
        expect(result, contains('New notes'));
        expect(result, isNot(contains('Original')));
      });

      test('throws NotFoundException when session not found', () async {
        // Arrange
        when(
          () => mockSessionRepo.getSession(999),
        ).thenAnswer((_) async => Result.success(null));

        // Act & Assert
        expect(
          () async => await sessionTools
              .firstWhere((t) => t.name == 'update_session_notes')
              .execute({'session_id': 999, 'notes': 'Notes'}),
          throwsA(
            isA<NotFoundException>().having(
              (e) => e.code,
              'code',
              'SESSION_NOT_FOUND',
            ),
          ),
        );
      });
    });
  });
}
