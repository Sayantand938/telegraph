import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:telegraph/models/finance_transaction.dart';

class FinanceDatabase {
  static final FinanceDatabase _instance = FinanceDatabase._internal();
  factory FinanceDatabase() => _instance;
  FinanceDatabase._internal();

  static Database? _database;
  bool _initializationAttempted = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_initializationAttempted) {
      throw Exception('Finance database initialization previously failed');
    }
    _initializationAttempted = true;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> reinitialize() async {
    _database = null;
    _initializationAttempted = false;
    await database;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'telegraph_finance.db');

      developer.log(
        'Attempting to create finance database at: $path',
        name: 'FinanceDatabase',
      );

      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        developer.log(
          'Creating directory: ${directory.path}',
          name: 'FinanceDatabase',
        );
        await directory.create(recursive: true);
      }

      final db = await openDatabase(path, version: 1, onCreate: _onCreate);
      developer.log(
        'Finance database initialized successfully at: $path',
        name: 'FinanceDatabase',
      );
      return db;
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing finance database at primary location: $e',
        name: 'FinanceDatabase',
        error: e,
        stackTrace: stackTrace,
      );

      try {
        final fallbackPath = join(
          Directory.current.path,
          'telegraph_finance.db',
        );
        final absolutePath = File(fallbackPath).absolute.path;
        developer.log(
          'Attempting fallback finance database at: $absolutePath',
          name: 'FinanceDatabase',
        );

        final db = await openDatabase(
          absolutePath,
          version: 1,
          onCreate: _onCreate,
        );
        developer.log(
          'Fallback finance database initialized successfully at: $absolutePath',
          name: 'FinanceDatabase',
        );
        return db;
      } catch (fallbackError, fallbackStack) {
        developer.log(
          'Fallback also failed: $fallbackError',
          name: 'FinanceDatabase',
          error: fallbackError,
          stackTrace: fallbackStack,
        );
        rethrow;
      }
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE finance_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        event_timestamp TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<int> createTransaction(FinanceTransaction transaction) async {
    final db = await database;
    return await db.insert('finance_transactions', transaction.toMap());
  }

  Future<FinanceTransaction?> getTransaction(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'finance_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FinanceTransaction.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FinanceTransaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'finance_transactions',
      orderBy: 'event_timestamp DESC',
    );

    return List.generate(
      maps.length,
      (i) => FinanceTransaction.fromMap(maps[i]),
    );
  }

  Future<List<FinanceTransaction>> getTransactionsByType(
    TransactionType type,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'finance_transactions',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'event_timestamp DESC',
    );

    return List.generate(
      maps.length,
      (i) => FinanceTransaction.fromMap(maps[i]),
    );
  }

  Future<List<FinanceTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'finance_transactions',
      where: 'event_timestamp >= ? AND event_timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'event_timestamp DESC',
    );

    return List.generate(
      maps.length,
      (i) => FinanceTransaction.fromMap(maps[i]),
    );
  }

  Future<double> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;
    String whereClause = 'type = ?';
    List<dynamic> whereArgs = [type.name];

    if (start != null && end != null) {
      whereClause += ' AND event_timestamp >= ? AND event_timestamp <= ?';
      whereArgs.addAll([start.toIso8601String(), end.toIso8601String()]);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM finance_transactions WHERE $whereClause',
      whereArgs,
    );

    final total = result.first['total'];
    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<int> updateTransaction(FinanceTransaction transaction) async {
    final db = await database;
    return await db.update(
      'finance_transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'finance_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
