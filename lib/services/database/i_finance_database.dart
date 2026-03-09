import 'package:telegraph/models/finance_transaction.dart';
import 'i_base_database.dart';

abstract class IFinanceDatabase extends IBaseDatabase<FinanceTransaction> {
  String get tableName;

  Future<int> createTransaction(FinanceTransaction transaction);
  Future<FinanceTransaction?> getTransaction(int id);
  Future<List<FinanceTransaction>> getAllTransactions();
  Future<int> updateTransaction(FinanceTransaction transaction);
  Future<int> deleteTransaction(int id);

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
