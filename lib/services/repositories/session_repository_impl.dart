import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/database/i_session_database.dart';
import 'package:telegraph/services/repositories/i_session_repository.dart';
import 'package:telegraph/core/errors/result.dart';
import 'package:telegraph/core/errors/exceptions.dart';

/// Concrete implementation of ISessionRepository.
/// Delegates to ISessionDatabase for data access and wraps errors in Result.
class SessionRepository implements ISessionRepository {
  final ISessionDatabase _database;

  SessionRepository(this._database);

  @override
  Future<Result<int>> createSession({
    String? notes,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final id = await _database.createSession(
        notes: notes,
        startTime: startTime,
        endTime: endTime,
      );
      return Result.success(id);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } on BusinessLogicException catch (e) {
      return Result.failure(
        BusinessLogicException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to create session: $e',
          code: 'DB_CREATE_SESSION_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<Session?>> getSession(int id) async {
    try {
      final session = await _database.getSession(id);
      return Result.success(session);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get session: $e',
          code: 'DB_GET_SESSION_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<Session>>> getAllSessions() async {
    try {
      final sessions = await _database.getAllSessions();
      return Result.success(sessions);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get all sessions: $e',
          code: 'DB_GET_ALL_SESSIONS_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<int>> updateSession(Session session) async {
    try {
      final result = await _database.updateSession(session);
      if (result > 0) {
        return Result.success(result);
      } else {
        return Result.failure(
          NotFoundException(
            'Session ${session.id} not found',
            code: 'SESSION_NOT_FOUND',
          ),
        );
      }
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to update session: $e',
          code: 'DB_UPDATE_SESSION_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<int>> deleteSession(int id) async {
    try {
      final result = await _database.deleteSession(id);
      if (result > 0) {
        return Result.success(result);
      } else {
        return Result.failure(
          NotFoundException('Session $id not found', code: 'SESSION_NOT_FOUND'),
        );
      }
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to delete session: $e',
          code: 'DB_DELETE_SESSION_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<EndSessionResult?>> endActiveSession({String? notes}) async {
    try {
      final result = await _database.endActiveSession(notes: notes);
      return Result.success(result);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } on NotFoundException catch (e) {
      return Result.failure(
        NotFoundException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to end active session: $e',
          code: 'DB_END_ACTIVE_SESSION_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<EndSessionResult?>> endSession(int id, {String? notes}) async {
    try {
      final result = await _database.endSession(id, notes: notes);
      return Result.success(result);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } on NotFoundException catch (e) {
      return Result.failure(
        NotFoundException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to end session: $e',
          code: 'DB_END_SESSION_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> hasOverlap(
    String start,
    String? end, {
    int? excludeId,
  }) async {
    try {
      final hasOverlap = await _database.hasOverlap(
        start,
        end,
        excludeId: excludeId,
      );
      return Result.success(hasOverlap);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to check overlap: $e',
          code: 'DB_CHECK_OVERLAP_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<Session>>> getSessionsByEndTimeIsNull() async {
    try {
      final sessions = await _database.getSessionsByEndTimeIsNull();
      return Result.success(sessions);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get sessions with null end time: $e',
          code: 'DB_GET_SESSIONS_BY_NULL_END_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<Session>>> getSessionsByEndTimeIsNotNull() async {
    try {
      final sessions = await _database.getSessionsByEndTimeIsNotNull();
      return Result.success(sessions);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get sessions with non-null end time: $e',
          code: 'DB_GET_SESSIONS_BY_NOT_NULL_END_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<Session?>> getMostRecentActiveSession() async {
    try {
      final session = await _database.getMostRecentActiveSession();
      return Result.success(session);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get most recent active session: $e',
          code: 'DB_GET_MOST_RECENT_ACTIVE_SESSION_FAILED',
          originalError: e,
        ),
      );
    }
  }
}
