import 'package:telegraph/models/session.dart';
import 'i_base_database.dart';

abstract class ISessionDatabase extends IBaseDatabase<Session> {
  String get tableName;

  Future<List<Session>> getAllSessions();
  Future<int> createSession({
    String? notes,
    String? startTime,
    String? endTime,
  });
  Future<Session?> getSession(int id);
  Future<int> updateSession(Session session);
  Future<int> deleteSession(int id);

  Future<EndSessionResult?> endActiveSession({String? notes});
  Future<EndSessionResult?> endSession(int id, {String? notes});
  Future<bool> hasOverlap(String start, String? end, {int? excludeId});
}

class EndSessionResult {
  final int originalSessionId;
  final int finalSessionId;
  final int totalSessionsCreated;
  final bool splitOccurred;

  EndSessionResult({
    required this.originalSessionId,
    required this.finalSessionId,
    required this.totalSessionsCreated,
    required this.splitOccurred,
  });
}
