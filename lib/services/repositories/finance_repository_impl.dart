import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/services/database/i_finance_database.dart';
import 'package:telegraph/services/repositories/i_finance_repository.dart';
import 'package:telegraph/core/errors/result.dart';
import 'package:telegraph/core/errors/exceptions.dart';

/// Concrete implementation of IFinanceRepository.
/// Delegates to IFinanceDatabase for data access and wraps errors in Result.
class FinanceRepository implements IFinanceRepository {
  final IFinanceDatabase _database;

  FinanceRepository(this._database);

  @override
  Future<Result<int>> createTransaction(FinanceTransaction transaction) async {
    try {
      final id = await _database.createTransaction(transaction);
      return Result.success(id);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to create transaction: $e',
          code: 'DB_CREATE_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<FinanceTransaction?>> getTransaction(int id) async {
    try {
      final transaction = await _database.getTransaction(id);
      return Result.success(transaction);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get transaction: $e',
          code: 'DB_GET_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<FinanceTransaction>>> getAllTransactions() async {
    try {
      final transactions = await _database.getAllTransactions();
      return Result.success(transactions);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get all transactions: $e',
          code: 'DB_GET_ALL_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<int>> updateTransaction(FinanceTransaction transaction) async {
    try {
      final result = await _database.updateTransaction(transaction);
      if (result > 0) {
        return Result.success(result);
      } else {
        return Result.failure(
          NotFoundException(
            'Transaction ${transaction.id} not found',
            code: 'TRANSACTION_NOT_FOUND',
          ),
        );
      }
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to update transaction: $e',
          code: 'DB_UPDATE_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<int>> deleteTransaction(int id) async {
    try {
      final result = await _database.deleteTransaction(id);
      if (result > 0) {
        return Result.success(result);
      } else {
        return Result.failure(
          NotFoundException(
            'Transaction $id not found',
            code: 'TRANSACTION_NOT_FOUND',
          ),
        );
      }
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to delete transaction: $e',
          code: 'DB_DELETE_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<FinanceTransaction>>> getTransactionsByType(
    TransactionType type,
  ) async {
    try {
      final transactions = await _database.getTransactionsByType(type);
      return Result.success(transactions);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get transactions by type: $e',
          code: 'DB_GET_BY_TYPE_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<FinanceTransaction>>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transactions = await _database.getTransactionsByDateRange(
        start,
        end,
      );
      return Result.success(transactions);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get transactions by date range: $e',
          code: 'DB_GET_BY_DATE_FAILED',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<double>> getTotalByType(
    TransactionType type, {
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final total = await _database.getTotalByType(
        type,
        start: start,
        end: end,
      );
      return Result.success(total);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseException(
          e.message,
          code: e.code,
          originalError: e.originalError,
        ),
      );
    } catch (e) {
      return Result.failure(
        DatabaseException(
          'Failed to get total by type: $e',
          code: 'DB_GET_TOTAL_FAILED',
          originalError: e,
        ),
      );
    }
  }
}
