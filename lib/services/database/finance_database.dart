import 'package:sqflite/sqflite.dart';
import 'package:telegraph/models/finance_transaction.dart';
import 'base_database.dart';

class FinanceDatabase extends BaseDatabase<FinanceTransaction> {
  static final FinanceDatabase _instance = FinanceDatabase._internal();
  factory FinanceDatabase() => _instance;
  FinanceDatabase._internal()
    : super('telegraph_finance.db', 'FinanceDatabase');

  @override
  String get tableName => 'finance_transactions';

  @override
  Map<String, dynamic> toMap(FinanceTransaction model) {
    return model.toMap();
  }

  @override
  FinanceTransaction fromMap(Map<String, dynamic> map) {
    return FinanceTransaction.fromMap(map);
  }

  @override
  Future<void> onCreate(Database db, int version) async {
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

  // Wrapper methods for backward compatibility
  Future<int> createTransaction(FinanceTransaction transaction) async =>
      create(transaction);
  Future<FinanceTransaction?> getTransaction(int id) async => get(id);
  Future<List<FinanceTransaction>> getAllTransactions() async => getAll();
  Future<int> updateTransaction(FinanceTransaction transaction) async =>
      update(transaction);
  Future<int> deleteTransaction(int id) async => delete(id);

  Future<List<FinanceTransaction>> getTransactionsByType(
    TransactionType type,
  ) async {
    final all = await getAll();
    return all.where((tx) => tx.type == type).toList();
  }

  Future<List<FinanceTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAll();
    return all.where((tx) {
      final ts = DateTime.parse(tx.eventTimestamp);
      return ts.isAfter(start.subtract(const Duration(seconds: 1))) &&
          ts.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Future<double> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  }) async {
    final transactions = start != null && end != null
        ? await getTransactionsByDateRange(start, end)
        : await getAll();

    final filtered = transactions.where((tx) => tx.type == type);
    return filtered.fold<double>(0.0, (sum, tx) => sum + tx.amount);
  }
}
