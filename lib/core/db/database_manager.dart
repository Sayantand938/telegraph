// lib/core/db/database_manager.dart
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

class DatabaseManager {
  final String? dbPathOverride;
  Database? _database;
  bool _isInitialized = false;

  DatabaseManager({this.dbPathOverride});

  Future<void> initialize(List<String> scripts) async {
    try {
      final db = await database;
      await db.execute('PRAGMA foreign_keys = ON');
      for (var script in scripts) {
        await db.execute(script);
      }
      _isInitialized = true;
    } catch (e, stackTrace) {
      debugPrint('❌ Database initialization failed: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB('telegraph.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;

    if (dbPathOverride != null) {
      // Handle :memory: or a provided directory path
      path = dbPathOverride == ':memory:'
          ? inMemoryDatabasePath
          : join(dbPathOverride!, filePath);
    } else {
      // Actual app usage
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, filePath);
    }

    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }

  bool get isReady => _isInitialized && _database != null && _database!.isOpen;
}
