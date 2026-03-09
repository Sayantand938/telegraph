import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/core/errors/result.dart';

/// High-level repository interface for finance operations.
/// Abstracts away database implementation details from business logic.
/// All methods return Result<T> for type-safe error handling.
abstract class IFinanceRepository {
  /// Creates a new transaction
  Future<Result<int>> createTransaction(FinanceTransaction transaction);

  /// Retrieves a transaction by ID
  Future<Result<FinanceTransaction?>> getTransaction(int id);

  /// Retrieves all transactions
  Future<Result<List<FinanceTransaction>>> getAllTransactions();

  /// Updates a transaction
  Future<Result<int>> updateTransaction(FinanceTransaction transaction);

  /// Deletes a transaction by ID
  Future<Result<int>> deleteTransaction(int id);

  /// Retrieves transactions filtered by type
  Future<Result<List<FinanceTransaction>>> getTransactionsByType(
    TransactionType type,
  );

  /// Retrieves transactions within a date range
  Future<Result<List<FinanceTransaction>>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Calculates total amount for a given type, optionally within a date range
  Future<Result<double>> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  });
}
