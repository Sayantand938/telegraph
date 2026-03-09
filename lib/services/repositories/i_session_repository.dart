import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/database/i_session_database.dart';
import 'package:telegraph/core/errors/result.dart';

/// High-level repository interface for session operations.
/// Abstracts away database implementation details from business logic.
/// All methods return `Result<T>` for type-safe error handling.
abstract class ISessionRepository {
  /// Creates a new session
  Future<Result<int>> createSession({
    String? notes,
    String? startTime,
    String? endTime,
  });

  /// Retrieves a session by ID
  Future<Result<Session?>> getSession(int id);

  /// Retrieves all sessions
  Future<Result<List<Session>>> getAllSessions();

  /// Updates a session
  Future<Result<int>> updateSession(Session session);

  /// Deletes a session by ID
  Future<Result<int>> deleteSession(int id);

  /// Ends the active session (if any) and returns the result
  Future<Result<EndSessionResult?>> endActiveSession({String? notes});

  /// Ends a specific session, potentially splitting it across days
  Future<Result<EndSessionResult?>> endSession(int id, {String? notes});

  /// Checks if a new session would overlap with existing sessions
  Future<Result<bool>> hasOverlap(String start, String? end, {int? excludeId});

  /// Retrieves all sessions where endTime is null (active sessions)
  Future<Result<List<Session>>> getSessionsByEndTimeIsNull();

  /// Retrieves all sessions where endTime is not null (completed sessions)
  Future<Result<List<Session>>> getSessionsByEndTimeIsNotNull();

  /// Retrieves the most recent active session (endTime is null)
  Future<Result<Session?>> getMostRecentActiveSession();
}
