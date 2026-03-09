import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:developer' as developer;

class Session {
  final int? id;
  final String startTime;
  final String? endTime;
  final String? notes;

  Session({this.id, required this.startTime, this.endTime, this.notes});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'notes': notes,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      notes: map['notes'],
    );
  }

  Session copyWith({
    int? id,
    String? startTime,
    String? endTime,
    String? notes,
  }) {
    return Session(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }
}

class SessionDatabase {
  static final SessionDatabase _instance = SessionDatabase._internal();
  factory SessionDatabase() => _instance;
  SessionDatabase._internal();

  static Database? _database;
  bool _initializationAttempted = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_initializationAttempted) {
      throw Exception('Database initialization previously failed');
    }
    _initializationAttempted = true;
    _database = await _initDatabase();
    return _database!;
  }

  /// Force reinitialize the database (useful for recovery)
  Future<void> reinitialize() async {
    _database = null;
    _initializationAttempted = false;
    await database;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'telegraph.db');

      developer.log(
        'Attempting to create database at: $path',
        name: 'SessionDatabase',
      );

      // Ensure directory exists
      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        developer.log(
          'Creating directory: ${directory.path}',
          name: 'SessionDatabase',
        );
        await directory.create(recursive: true);
      }

      // ✅ Use global openDatabase() - it respects the databaseFactory override from main.dart
      final db = await openDatabase(path, version: 1, onCreate: _onCreate);
      developer.log(
        'Database initialized successfully at: $path',
        name: 'SessionDatabase',
      );
      return db;
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing database at primary location: $e',
        name: 'SessionDatabase',
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback to current directory for desktop
      try {
        final fallbackPath = join(Directory.current.path, 'telegraph.db');
        final absolutePath = File(fallbackPath).absolute.path;
        developer.log(
          'Attempting fallback database at: $absolutePath',
          name: 'SessionDatabase',
        );

        // ✅ Use global openDatabase() here too
        final db = await openDatabase(
          absolutePath,
          version: 1,
          onCreate: _onCreate,
        );
        developer.log(
          'Fallback database initialized successfully at: $absolutePath',
          name: 'SessionDatabase',
        );
        return db;
      } catch (fallbackError, fallbackStack) {
        developer.log(
          'Fallback also failed: $fallbackError',
          name: 'SessionDatabase',
          error: fallbackError,
          stackTrace: fallbackStack,
        );
        rethrow;
      }
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        notes TEXT
      )
    ''');
  }

  Future<int> createSession({String? notes}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('sessions', {
      'start_time': now,
      'end_time': null,
      'notes': notes,
    });
  }

  Future<Session?> getSession(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'start_time DESC',
    );

    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }

  Future<int> updateSession(Session session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> endSession(int id, {String? notes}) async {
    final session = await getSession(id);
    if (session == null) return 0;

    final now = DateTime.now().toIso8601String();
    final updatedSession = session.copyWith(
      endTime: now,
      notes: notes ?? session.notes,
    );

    return await updateSession(updatedSession);
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
