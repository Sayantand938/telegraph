import 'package:telegraph/models/session.dart';
import 'package:telegraph/services/database/i_session_database.dart';
import 'package:telegraph/services/repositories/i_session_repository.dart';

/// Concrete implementation of ISessionRepository.
/// Delegates to ISessionDatabase for data access.
class SessionRepository implements ISessionRepository {
  final ISessionDatabase _database;

  SessionRepository(this._database);

  @override
  Future<int> createSession({
    String? notes,
    String? startTime,
    String? endTime,
  }) async {
    return await _database.createSession(
      notes: notes,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  Future<Session?> getSession(int id) async {
    return await _database.getSession(id);
  }

  @override
  Future<List<Session>> getAllSessions() async {
    return await _database.getAllSessions();
  }

  @override
  Future<int> updateSession(Session session) async {
    return await _database.updateSession(session);
  }

  @override
  Future<int> deleteSession(int id) async {
    return await _database.deleteSession(id);
  }

  @override
  Future<EndSessionResult?> endActiveSession({String? notes}) async {
    return await _database.endActiveSession(notes: notes);
  }

  @override
  Future<EndSessionResult?> endSession(int id, {String? notes}) async {
    return await _database.endSession(id, notes: notes);
  }

  @override
  Future<bool> hasOverlap(String start, String? end, {int? excludeId}) async {
    return await _database.hasOverlap(start, end, excludeId: excludeId);
  }
}
