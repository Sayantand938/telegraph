import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
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
  Future<List<Session>> getSessionsByEndTimeIsNull() async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
    );
    return maps.map(fromMap).toList();
  }

  @override
  Future<List<Session>> getSessionsByEndTimeIsNotNull() async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'end_time IS NOT NULL',
      orderBy: 'start_time DESC',
    );
    return maps.map(fromMap).toList();
  }

  @override
  Future<Session?> getMostRecentActiveSession() async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

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
    final activeSessions = await getSessionsByEndTimeIsNull();

    if (activeSessions.isEmpty) {
      return null;
    }

    // Already sorted by start_time DESC from query
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
    final newEnd = end != null ? DateTime.parse(end) : null;
    final db = await database;

    // Build WHERE clause based on overlap logic
    // Overlap occurs when:
    // - existing session is active (end_time IS NULL) and newStart >= existing.start_time
    // - OR existing session has end_time and newStart < existing.end_time AND newEnd > existing.start_time
    String whereClause;
    List<dynamic> whereArgs;

    if (newEnd == null) {
      // New session is active: overlaps with any active session that started at or before newStart
      whereClause = 'end_time IS NULL AND start_time <= ?';
      whereArgs = [start];
    } else {
      // New session has end time: overlaps with active sessions or sessions that overlap in time
      whereClause =
          '(end_time IS NULL AND start_time <= ?) OR (end_time IS NOT NULL AND ? < end_time AND ? > start_time)';
      whereArgs = [start, start, end];
    }

    // Add excludeId if provided
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1, // Only need to know if at least one overlaps
    );

    final hasOverlap = maps.isNotEmpty;
    if (hasOverlap) {
      final session = fromMap(maps.first);
      logger.log(
        Level.warning,
        'Overlap detected: new [$start, $end] overlaps with existing session ${session.id} [${session.startTime}, ${session.endTime}]',
      );
    }
    return hasOverlap;
  }
}
