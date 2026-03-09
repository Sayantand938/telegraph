import 'package:sqflite/sqflite.dart';
import 'package:telegraph/models/finance_transaction.dart';
import 'base_database.dart';
import 'i_finance_database.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IFinanceDatabase)
class FinanceDatabase extends BaseDatabase<FinanceTransaction>
    implements IFinanceDatabase {
  FinanceDatabase() : super('telegraph_finance.db', 'FinanceDatabase');

  @override
  String get tableName => 'finance_transactions';

  @override
  Map<String, dynamic> toMap(FinanceTransaction model) {
    return model.toJson();
  }

  @override
  FinanceTransaction fromMap(Map<String, dynamic> map) {
    return FinanceTransaction.fromJson(map);
  }

  @override
  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE finance_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_time TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  // Wrapper methods required by IFinanceDatabase
  @override
  Future<int> createTransaction(FinanceTransaction transaction) async =>
      create(transaction);

  @override
  Future<FinanceTransaction?> getTransaction(int id) async => get(id);

  @override
  Future<List<FinanceTransaction>> getAllTransactions() async => getAll();

  @override
  Future<int> updateTransaction(FinanceTransaction transaction) async =>
      update(transaction);

  @override
  Future<int> deleteTransaction(int id) async => delete(id);

  // Additional query methods
  @override
  Future<List<FinanceTransaction>> getTransactionsByType(
    TransactionType type,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'transaction_time DESC',
    );
    return maps.map(fromMap).toList();
  }

  @override
  Future<List<FinanceTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'transaction_time BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'transaction_time DESC',
    );
    return maps.map(fromMap).toList();
  }

  @override
  Future<double> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;

    String whereClause = 'type = ?';
    List<dynamic> whereArgs = [type.name];

    if (start != null && end != null) {
      whereClause += ' AND transaction_time BETWEEN ? AND ?';
      whereArgs.addAll([start.toIso8601String(), end.toIso8601String()]);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $tableName WHERE $whereClause',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
