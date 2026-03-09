import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:telegraph/core/errors/exceptions.dart';

abstract class BaseDatabase<T> {
  static final String _defaultLoggerName = 'BaseDatabase';

  final String dbName;
  final String? loggerName;
  Database? _databaseInstance;
  bool _initializationAttempted = false;
  final Database? _injectedDatabase;

  BaseDatabase(this.dbName, [this.loggerName]) : _injectedDatabase = null;

  /// Constructor for testing that allows injecting a pre-opened database.
  /// This is useful for in-memory databases where multiple instances
  /// need to share the same connection.
  BaseDatabase.injected(this._injectedDatabase, this.dbName, [this.loggerName]);

  // Abstract methods that subclasses must implement
  Map<String, dynamic> toMap(T model);
  T fromMap(Map<String, dynamic> map);
  String get tableName;
  Future<void> onCreate(Database db, int version);

  Future<Database> get database async {
    // If we have an injected database, use it directly
    if (_injectedDatabase != null) {
      return _injectedDatabase;
    }

    if (_databaseInstance != null) return _databaseInstance!;

    if (_initializationAttempted) {
      throw DatabaseException('Database initialization previously failed');
    }
    _initializationAttempted = true;

    final db = await _initDatabase();
    _databaseInstance = db;
    return db;
  }

  Future<void> reinitialize() async {
    _databaseInstance = null;
    _initializationAttempted = false;
    await database;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);

      developer.log(
        'Attempting to create database at: $path',
        name: loggerName ?? _defaultLoggerName,
      );

      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        developer.log(
          'Creating directory: ${directory.path}',
          name: loggerName ?? _defaultLoggerName,
        );
        await directory.create(recursive: true);
      }

      final db = await openDatabase(path, version: 1, onCreate: _onCreate);
      developer.log(
        'Database initialized successfully at: $path',
        name: loggerName ?? _defaultLoggerName,
      );
      return db;
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing database at primary location: $e',
        name: loggerName ?? _defaultLoggerName,
        error: e,
        stackTrace: stackTrace,
      );

      try {
        final fallbackPath = join(Directory.current.path, dbName);
        final absolutePath = File(fallbackPath).absolute.path;
        developer.log(
          'Attempting fallback database at: $absolutePath',
          name: loggerName ?? _defaultLoggerName,
        );

        final db = await openDatabase(
          absolutePath,
          version: 1,
          onCreate: _onCreate,
        );
        developer.log(
          'Fallback database initialized successfully at: $absolutePath',
          name: loggerName ?? _defaultLoggerName,
        );
        return db;
      } catch (fallbackError, fallbackStack) {
        developer.log(
          'Fallback also failed: $fallbackError',
          name: loggerName ?? _defaultLoggerName,
          error: fallbackError,
          stackTrace: fallbackStack,
        );
        throw DatabaseException(
          'Failed to initialize database',
          originalError: e,
          code: 'DB_INIT_FAILED',
        );
      }
    }
  }

  Future _onCreate(Database db, int version) async {
    await onCreate(db, version);
  }

  Future<int> create(T model) async {
    final db = await database;
    return await db.insert(tableName, toMap(model));
  }

  Future<T?> get(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  Future<List<T>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  Future<int> update(T model) async {
    final db = await database;
    final map = toMap(model);
    final id = map['id'];
    if (id == null) {
      throw ValidationException(
        'Model must have an id to update',
        code: 'MISSING_ID',
      );
    }
    return await db.update(tableName, map, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
