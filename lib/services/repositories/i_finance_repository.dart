import 'package:telegraph/models/finance_transaction.dart';

/// High-level repository interface for finance operations.
/// Abstracts away database implementation details from business logic.
abstract class IFinanceRepository {
  /// Creates a new transaction
  Future<int> createTransaction(FinanceTransaction transaction);

  /// Retrieves a transaction by ID
  Future<FinanceTransaction?> getTransaction(int id);

  /// Retrieves all transactions
  Future<List<FinanceTransaction>> getAllTransactions();

  /// Updates a transaction
  Future<int> updateTransaction(FinanceTransaction transaction);

  /// Deletes a transaction by ID
  Future<int> deleteTransaction(int id);

  /// Retrieves transactions filtered by type
  Future<List<FinanceTransaction>> getTransactionsByType(TransactionType type);

  /// Retrieves transactions within a date range
  Future<List<FinanceTransaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Calculates total amount for a given type, optionally within a date range
  Future<double> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  });
}
