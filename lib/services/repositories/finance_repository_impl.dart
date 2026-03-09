import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/services/database/i_finance_database.dart';
import 'package:telegraph/services/repositories/i_finance_repository.dart';

/// Concrete implementation of IFinanceRepository.
/// Delegates to IFinanceDatabase for data access.
class FinanceRepository implements IFinanceRepository {
  final IFinanceDatabase _database;

  FinanceRepository(this._database);

  @override
  Future<int> createTransaction(FinanceTransaction transaction) async {
    return await _database.createTransaction(transaction);
  }

  @override
  Future<FinanceTransaction?> getTransaction(int id) async {
    return await _database.getTransaction(id);
  }

  @override
  Future<List<FinanceTransaction>> getAllTransactions() async {
    return await _database.getAllTransactions();
  }

  @override
  Future<int> updateTransaction(FinanceTransaction transaction) async {
    return await _database.updateTransaction(transaction);
  }

  @override
  Future<int> deleteTransaction(int id) async {
    return await _database.deleteTransaction(id);
  }

  @override
  Future<List<FinanceTransaction>> getTransactionsByType(
    TransactionType type,
  ) async {
    return await _database.getTransactionsByType(type);
  }

  @override
  Future<List<FinanceTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _database.getTransactionsByDateRange(start, end);
  }

  @override
  Future<double> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  }) async {
    return await _database.getTotalByType(type, start: start, end: end);
  }
}
