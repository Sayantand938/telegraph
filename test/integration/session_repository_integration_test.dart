// ignore_for_file: unnecessary_non_null_assertion

import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/repositories/i_session_repository.dart';
import 'package:telegraph/services/tools/session_tools.dart';
import 'package:telegraph/services/tools/tool_definitions.dart';
import 'package:telegraph/core/errors/result.dart';
import '../../test/support/database_test_helper.dart';

void main() {
  late ISessionRepository repository;
  late List<Tool> sessionTools;

  setUpAll(() async {
    // Initialize in-memory database for all tests
    await DatabaseTestHelper.initialize();
    repository = await DatabaseTestHelper.getSessionRepository();
    // Create tools with real repository (integration test - no mocks)
    sessionTools = getSessionTools(repository);
  });

  tearDownAll(() async {
    await DatabaseTestHelper.cleanup();
  });

  setUp(() async {
    // Clear the database before each test
    await DatabaseTestHelper.clearAllData();
  });

  group('Session Repository Integration Tests', () {
    test('creates and retrieves a session', () async {
      // Arrange
      final now = DateTime.now().toIso8601String();
      final createResult = await repository.createSession(
        startTime: now,
        notes: 'Test session',
      );
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create session: $error'),
      );

      // Act
      final getResult = await repository.getSession(id);

      // Assert
      final retrieved = getResult.when(
        success: (session) => session,
        failure: (error) => fail('Failed to get session: $error'),
      );
      expect(retrieved, isNotNull);
      expect(retrieved!.id, id);
      expect(retrieved.startTime, now);
      expect(retrieved.notes, 'Test session');
      expect(retrieved.endTime, isNull); // Active session
    });

    test('ends an active session', () async {
      // Arrange - create an active session
      final now = DateTime.now().toIso8601String();
      final createResult = await repository.createSession(startTime: now);
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create session: $error'),
      );

      // Act
      final endResult = await repository.endActiveSession(notes: 'Completed');

      // Assert
      final endSessionResult = endResult.when(
        success: (result) => result,
        failure: (error) => fail('Failed to end session: $error'),
      );
      expect(endSessionResult, isNotNull);
      expect(endSessionResult!.splitOccurred, isFalse);
      expect(endSessionResult.finalSessionId, id);

      // Verify session is now completed
      final getResult = await repository.getSession(id);
      final session = getResult.when(
        success: (s) => s,
        failure: (error) => fail('Failed to get session: $error'),
      );
      expect(session!.endTime, isNotNull);
    });

    test('gets all sessions', () async {
      // Arrange - create multiple sessions
      final now = DateTime.now().toIso8601String();
      await repository.createSession(startTime: now, notes: 'Session 1');
      await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        notes: 'Session 2',
      );

      // Act
      final allResult = await repository.getAllSessions();

      // Assert
      final all = allResult.when(
        success: (sessions) => sessions,
        failure: (error) => fail('Failed to get all sessions: $error'),
      );
      expect(all.length, 2);
    });

    test('gets active sessions (end_time IS NULL)', () async {
      // Arrange
      final now = DateTime.now().toIso8601String();
      await repository.createSession(startTime: now, notes: 'Active 1');
      await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        notes: 'Completed',
      );
      await repository.createSession(startTime: now, notes: 'Active 2');

      // Act
      final activeResult = await repository.getSessionsByEndTimeIsNull();

      // Assert
      final active = activeResult.when(
        success: (sessions) => sessions,
        failure: (error) => fail('Failed to get active sessions: $error'),
      );
      expect(active.length, 2);
      expect(active.every((s) => s.endTime == null), isTrue);
    });

    test('gets completed sessions (end_time IS NOT NULL)', () async {
      // Arrange
      final now = DateTime.now().toIso8601String();
      await repository.createSession(startTime: now, notes: 'Active');
      await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        notes: 'Completed 1',
      );
      await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        notes: 'Completed 2',
      );

      // Act
      final completedResult = await repository.getSessionsByEndTimeIsNotNull();

      // Assert
      final completed = completedResult.when(
        success: (sessions) => sessions,
        failure: (error) => fail('Failed to get completed sessions: $error'),
      );
      expect(completed.length, 2);
      expect(completed.every((s) => s.endTime != null), isTrue);
    });

    test('deletes a session', () async {
      // Arrange
      final now = DateTime.now().toIso8601String();
      final createResult = await repository.createSession(startTime: now);
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create session: $error'),
      );

      // Act
      final deleteResult = await repository.deleteSession(id);

      // Assert
      final rowsAffected = deleteResult.when(
        success: (count) => count,
        failure: (error) => fail('Failed to delete session: $error'),
      );
      expect(rowsAffected, 1);

      // Verify session is gone
      final getResult = await repository.getSession(id);
      final session = getResult.when(
        success: (s) => s,
        failure: (error) => fail('Failed to get session: $error'),
      );
      expect(session, isNull);
    });

    test('prevents overlapping sessions', () async {
      // Arrange - create a session that spans a time range
      final now = DateTime.now();
      final start1 = now.subtract(const Duration(hours: 1)).toIso8601String();
      final end1 = now.add(const Duration(hours: 1)).toIso8601String();
      await repository.createSession(startTime: start1, endTime: end1);

      // Act & Assert - overlapping start
      final overlap1 = await repository.hasOverlap(
        now.subtract(const Duration(minutes: 30)).toIso8601String(),
        null,
      );
      expect(overlap1.when(success: (v) => v, failure: (e) => false), isTrue);

      // Act & Assert - non-overlapping start
      final noOverlap = await repository.hasOverlap(
        now.add(const Duration(hours: 2)).toIso8601String(),
        now.add(const Duration(hours: 3)).toIso8601String(),
      );
      expect(noOverlap.when(success: (v) => v, failure: (e) => false), isFalse);
    });
  });

  group('Session Tools Integration Tests (Real Database)', () {
    test('list_sessions returns formatted output with all sessions', () async {
      // Arrange - create sessions directly in database
      final now = DateTime.now().toIso8601String();
      await repository.createSession(startTime: now, notes: 'First session');
      await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        notes: 'Second session',
      );

      // Act
      final result = await sessionTools
          .firstWhere((t) => t.name == 'list_sessions')
          .execute({});

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.value, contains('Sessions:'));
      expect(successResult.value, contains('First session'));
      expect(successResult.value, contains('Second session'));
    });

    test('list_sessions filters by status=active', () async {
      // Arrange
      final now = DateTime.now().toIso8601String();
      await repository.createSession(startTime: now, notes: 'Active');
      await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        notes: 'Completed',
      );

      // Act
      final result = await sessionTools
          .firstWhere((t) => t.name == 'list_sessions')
          .execute({'status': 'active'});

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.value, contains('Active'));
      expect(successResult.value, isNot(contains('Completed')));
    });

    test('list_sessions filters by status=completed', () async {
      // Arrange
      final now = DateTime.now().toIso8601String();
      await repository.createSession(startTime: now, notes: 'Active');
      await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        notes: 'Completed',
      );

      // Act
      final result = await sessionTools
          .firstWhere((t) => t.name == 'list_sessions')
          .execute({'status': 'completed'});

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.value, contains('Completed'));
      expect(successResult.value, isNot(contains('Active')));
    });

    test('get_session returns details for specific session', () async {
      // Arrange
      final now = DateTime.now().toIso8601String();
      final createResult = await repository.createSession(
        startTime: now,
        endTime: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        notes: 'Test session',
      );
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create session: $error'),
      );

      // Act
      final result = await sessionTools
          .firstWhere((t) => t.name == 'get_session')
          .execute({'session_id': id});

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.value, contains('Session $id:'));
      expect(successResult.value, contains('Test session'));
    });

    test('get_active_session returns most recent active session', () async {
      // Arrange - create multiple active sessions
      final now = DateTime.now();
      await repository.createSession(
        startTime: now.subtract(const Duration(hours: 2)).toIso8601String(),
        notes: 'Older',
      );
      await repository.createSession(
        startTime: now.toIso8601String(),
        notes: 'Newer',
      );

      // Act
      final result = await sessionTools
          .firstWhere((t) => t.name == 'get_active_session')
          .execute({});

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.value, contains('Newer'));
      expect(successResult.value, contains('Active Session ID:'));
    });

    test('start_session creates new session with validation', () async {
      // Act
      final result = await sessionTools
          .firstWhere((t) => t.name == 'start_session')
          .execute({'notes': 'Integration test session'});

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.value, contains('Session started with ID:'));

      // Verify it's in the database
      final allResult = await repository.getAllSessions();
      final sessions = allResult.when(
        success: (s) => s,
        failure: (e) => fail('Failed to get sessions: $e'),
      );
      expect(sessions.length, 1);
      expect(sessions.first.notes, 'Integration test session');
    });

    test('end_session ends the active session', () async {
      // Arrange - create an active session
      final now = DateTime.now().toIso8601String();
      final createResult = await repository.createSession(startTime: now);
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create session: $error'),
      );

      // Act
      final result = await sessionTools
          .firstWhere((t) => t.name == 'end_session')
          .execute({'notes': 'Ended via tool'});

      // Assert
      expect(result, isA<Success<String>>());
      final successResult = result as Success<String>;
      expect(successResult.value, contains('ended successfully'));

      // Verify session is completed with notes
      final getResult = await repository.getSession(id);
      final session = getResult.when(
        success: (s) => s,
        failure: (error) => fail('Failed to get session: $error'),
      );
      expect(session!.endTime, isNotNull);
    });
  });
}
