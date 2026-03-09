import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;
import 'package:telegraph/models/session.dart';
import 'base_database.dart';
import 'i_session_database.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ISessionDatabase)
class SessionDatabase extends BaseDatabase<Session>
    implements ISessionDatabase {
  SessionDatabase() : super('telegraph.db', 'SessionDatabase');

  /// Constructor for testing with an injected database connection
  SessionDatabase.injected(Database db, String? name)
    : super.injected(db, name ?? 'telegraph.db', 'SessionDatabase');

  @override
  String get tableName => 'sessions';

  @override
  Map<String, dynamic> toMap(Session model) {
    return model.toJson();
  }

  @override
  Session fromMap(Map<String, dynamic> map) {
    return Session.fromJson(map);
  }

  @override
  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        notes TEXT
      )
    ''');
  }

  // Wrapper methods for backward compatibility
  @override
  Future<List<Session>> getAllSessions() async => getAll();
  @override
  Future<int> createSession({
    String? notes,
    String? startTime,
    String? endTime,
  }) async {
    final now = DateTime.now().toIso8601String();
    return await create(
      Session(notes: notes, startTime: startTime ?? now, endTime: endTime),
    );
  }

  @override
  Future<Session?> getSession(int id) async => get(id);
  @override
  Future<int> updateSession(Session session) async => update(session);
  @override
  Future<int> deleteSession(int id) async => delete(id);

  @override
  Future<EndSessionResult?> endActiveSession({String? notes}) async {
    final allSessions = await getAll();
    final activeSessions = allSessions.where((s) => s.endTime == null).toList();

    if (activeSessions.isEmpty) {
      return null;
    }

    activeSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    final session = activeSessions.first;
    final id = session.id!;

    return await endSession(id, notes: notes);
  }

  @override
  Future<EndSessionResult?> endSession(int id, {String? notes}) async {
    final session = await get(id);
    if (session == null) {
      return null;
    }
    if (session.endTime != null) {
      return null; // Already ended
    }

    final now = DateTime.now();
    final start = DateTime.parse(session.startTime);

    if (start.year == now.year &&
        start.month == now.month &&
        start.day == now.day) {
      final updatedNotes = session.notes?.isNotEmpty == true
          ? session.notes
          : notes;
      final updatedSession = session.copyWith(
        endTime: now.toIso8601String(),
        notes: updatedNotes,
      );
      await update(updatedSession);
      return EndSessionResult(
        originalSessionId: id,
        finalSessionId: id,
        totalSessionsCreated: 1,
        splitOccurred: false,
      );
    } else {
      int? lastInsertedId;
      int count = 0;
      final db = await database;

      await db.transaction((txn) async {
        await txn.delete('sessions', where: 'id = ?', whereArgs: [id]);

        DateTime currentStart = start;

        while (currentStart.isBefore(now)) {
          count++;
          DateTime nextMidnight = DateTime(
            currentStart.year,
            currentStart.month,
            currentStart.day + 1,
          );
          DateTime segmentEnd = nextMidnight.isBefore(now) ? nextMidnight : now;

          String? segmentNotes;
          if (count == 1) {
            segmentNotes = session.notes;
          } else if (segmentEnd == now) {
            segmentNotes = notes;
          } else {
            segmentNotes = "Split from session $id";
          }

          lastInsertedId = await txn.insert('sessions', {
            'start_time': currentStart.toIso8601String(),
            'end_time': segmentEnd.toIso8601String(),
            'notes': segmentNotes,
          });

          if (segmentEnd == now) break;
          currentStart = segmentEnd;
        }
      });

      return EndSessionResult(
        originalSessionId: id,
        finalSessionId: lastInsertedId!,
        totalSessionsCreated: count,
        splitOccurred: true,
      );
    }
  }

  @override
  Future<bool> hasOverlap(String start, String? end, {int? excludeId}) async {
    final allSessions = await getAll();

    final newStart = DateTime.parse(start);
    final newEnd = end != null ? DateTime.parse(end) : null;

    for (final map in allSessions) {
      final session = map;

      if (excludeId != null && session.id == excludeId) {
        continue;
      }

      final existingStart = DateTime.parse(session.startTime);
      final existingEnd = session.endTime != null
          ? DateTime.parse(session.endTime!)
          : null;

      bool overlap = false;

      if (existingEnd == null) {
        overlap =
            newStart.isAfter(existingStart) ||
            newStart.isAtSameMomentAs(existingStart);
      } else if (newEnd == null) {
        overlap =
            existingStart.isAfter(newStart) ||
            existingStart.isAtSameMomentAs(newStart);
      } else {
        overlap =
            newStart.isBefore(existingEnd) && existingStart.isBefore(newEnd);
      }

      if (overlap) {
        developer.log(
          'Overlap detected: new [$start, $end] overlaps with existing session ${session.id} [${session.startTime}, ${session.endTime}]',
          name: 'SessionDatabase',
        );
        return true;
      }
    }

    return false;
  }
}
