// lib/services/database/database_helper.dart
import 'package:path/path.dart';
// ✅ Add this for desktop support
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // ✅ Add this static init method for FFI
  static void init() {
    sqfliteFfiInit();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // ✅ Use FFI factory for desktop, default for mobile
    final databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'telegraph.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions(
        id TEXT PRIMARY KEY,
        start_time TEXT NOT NULL,
        end_time TEXT,
        note TEXT,
        tags TEXT,
        is_active INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ✅ CRUD operations (same as before)
  Future<int> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    return await db.insert(
      'sessions',
      session,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> querySessions({
    String? where,
    List<Object>? whereArgs,
  }) async {
    final db = await database;
    return await db.query(
      'sessions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'start_time DESC',
    );
  }

  Future<int> updateSession(String id, Map<String, dynamic> session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSession(String id) async {
    final db = await database;
    return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
