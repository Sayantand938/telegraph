import 'package:telegraph/models/finance_transaction.dart';
import 'i_base_database.dart';

abstract class IFinanceDatabase extends IBaseDatabase<FinanceTransaction> {
  String get tableName;

  Future<int> createTransaction(FinanceTransaction transaction) async =>
      create(transaction);
  Future<FinanceTransaction?> getTransaction(int id) async => get(id);
  Future<List<FinanceTransaction>> getAllTransactions() async => getAll();
  Future<int> updateTransaction(FinanceTransaction transaction) async =>
      update(transaction);
  Future<int> deleteTransaction(int id) async => delete(id);

  Future<List<FinanceTransaction>> getTransactionsByType(TransactionType type);
  Future<List<FinanceTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<double> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  });
}
