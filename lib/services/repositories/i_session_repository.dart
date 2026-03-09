import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/database/i_session_database.dart';

/// High-level repository interface for session operations.
/// Abstracts away database implementation details from business logic.
abstract class ISessionRepository {
  /// Creates a new session
  Future<int> createSession({
    String? notes,
    String? startTime,
    String? endTime,
  });

  /// Retrieves a session by ID
  Future<Session?> getSession(int id);

  /// Retrieves all sessions
  Future<List<Session>> getAllSessions();

  /// Updates a session
  Future<int> updateSession(Session session);

  /// Deletes a session by ID
  Future<int> deleteSession(int id);

  /// Ends the active session (if any) and returns the result
  Future<EndSessionResult?> endActiveSession({String? notes});

  /// Ends a specific session, potentially splitting it across days
  Future<EndSessionResult?> endSession(int id, {String? notes});

  /// Checks if a new session would overlap with existing sessions
  Future<bool> hasOverlap(String start, String? end, {int? excludeId});
}
