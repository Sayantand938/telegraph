// ignore_for_file: unnecessary_non_null_assertion

import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/services/repositories/i_finance_repository.dart';
import 'package:telegraph/core/errors/result.dart';
import '../../test/support/database_test_helper.dart';

void main() {
  late IFinanceRepository repository;

  setUpAll(() async {
    // Initialize in-memory database for all tests
    await DatabaseTestHelper.initialize();
    repository = await DatabaseTestHelper.getFinanceRepository();
  });

  tearDownAll(() async {
    await DatabaseTestHelper.cleanup();
  });

  setUp(() async {
    // Clear the database before each test
    await DatabaseTestHelper.clearAllData();
  });

  group('FinanceRepository Integration Tests', () {
    test('creates and retrieves a transaction', () async {
      // Arrange
      final transaction = FinanceTransaction(
        type: TransactionType.income,
        amount: 100.0,
        transactionTime: '2025-01-15T12:00:00Z',
        note: 'Test income',
      );

      // Act
      final createResult = await repository.createTransaction(transaction);
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create transaction: $error'),
      );

      final getResult = await repository.getTransaction(id);

      // Assert
      expect(
        getResult,
        isA<Result<FinanceTransaction?>>().having(
          (result) =>
              result.when(success: (tx) => tx, failure: (error) => null),
          'transaction',
          isNotNull,
        ),
      );

      final retrieved = getResult.when(
        success: (tx) => tx,
        failure: (error) => fail('Failed to get transaction: $error'),
      );

      expect(retrieved!.type, TransactionType.income);
      expect(retrieved.amount, 100.0);
      expect(retrieved.transactionTime, '2025-01-15T12:00:00Z');
      expect(retrieved.note, 'Test income');
    });

    test('updates a transaction', () async {
      // Arrange
      final transaction = FinanceTransaction(
        type: TransactionType.expense,
        amount: 50.0,
        transactionTime: '2025-01-15T12:00:00Z',
      );
      final createResult = await repository.createTransaction(transaction);
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create transaction: $error'),
      );

      // Act
      final updated = transaction.copyWith(
        id: id,
        amount: 75.0,
        note: 'Updated note',
      );
      final updateResult = await repository.updateTransaction(updated);
      final int updateCount = updateResult.when(
        success: (count) => count,
        failure: (error) => fail('Failed to update transaction: $error'),
      );
      expect(updateCount, greaterThan(0));

      final getResult = await repository.getTransaction(id);

      // Assert
      final retrieved = getResult.when(
        success: (tx) => tx,
        failure: (error) => fail('Failed to get transaction: $error'),
      );
      expect(retrieved!.amount, 75.0);
      expect(retrieved.note, 'Updated note');
    });

    test('deletes a transaction', () async {
      // Arrange
      final transaction = FinanceTransaction(
        type: TransactionType.income,
        amount: 200.0,
        transactionTime: '2025-01-15T12:00:00Z',
      );
      final createResult = await repository.createTransaction(transaction);
      final id = createResult.when(
        success: (id) => id,
        failure: (error) => fail('Failed to create transaction: $error'),
      );

      // Act
      final deleteResult = await repository.deleteTransaction(id);
      final int rowsAffected = deleteResult.when(
        success: (count) => count,
        failure: (error) => fail('Failed to delete transaction: $error'),
      );
      expect(rowsAffected, greaterThan(0));

      final getResult = await repository.getTransaction(id);

      // Assert
      final retrieved = getResult.when(
        success: (tx) => tx,
        failure: (error) => fail('Failed to get transaction: $error'),
      );
      expect(retrieved, isNull);
    });

    test('gets all transactions', () async {
      // Arrange
      final now = DateTime.now();
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.income,
          amount: 100.0,
          transactionTime: now.toIso8601String(),
        ),
      );
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.expense,
          amount: 50.0,
          transactionTime: now.toIso8601String(),
        ),
      );

      // Act
      final allResult = await repository.getAllTransactions();

      // Assert
      final all = allResult.when(
        success: (transactions) => transactions,
        failure: (error) => fail('Failed to get all transactions: $error'),
      );
      expect(all.length, 2);
    });

    test('gets transactions by type', () async {
      // Arrange
      final now = DateTime.now();
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.income,
          amount: 100.0,
          transactionTime: now.toIso8601String(),
        ),
      );
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.expense,
          amount: 50.0,
          transactionTime: now.toIso8601String(),
        ),
      );

      // Act
      final incomeResult = await repository.getTransactionsByType(
        TransactionType.income,
      );
      final expensesResult = await repository.getTransactionsByType(
        TransactionType.expense,
      );

      // Assert
      final income = incomeResult.when(
        success: (transactions) => transactions,
        failure: (error) => fail('Failed to get income transactions: $error'),
      );
      final expenses = expensesResult.when(
        success: (transactions) => transactions,
        failure: (error) => fail('Failed to get expense transactions: $error'),
      );

      expect(income.length, 1);
      expect(income.first.amount, 100.0);
      expect(expenses.length, 1);
      expect(expenses.first.amount, 50.0);
    });

    test('gets transactions by date range', () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.income,
          amount: 100.0,
          transactionTime: yesterday.toIso8601String(),
        ),
      );
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.expense,
          amount: 50.0,
          transactionTime: now.toIso8601String(),
        ),
      );

      // Act
      final inRangeResult = await repository.getTransactionsByDateRange(
        now.subtract(const Duration(hours: 1)),
        tomorrow,
      );

      // Assert
      final inRange = inRangeResult.when(
        success: (transactions) => transactions,
        failure: (error) =>
            fail('Failed to get transactions by date range: $error'),
      );
      expect(inRange.length, 1);
      expect(inRange.first.amount, 50.0);
    });

    test('calculates total by type', () async {
      // Arrange
      final now = DateTime.now();
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.income,
          amount: 100.0,
          transactionTime: now.toIso8601String(),
        ),
      );
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.income,
          amount: 200.0,
          transactionTime: now.toIso8601String(),
        ),
      );
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.expense,
          amount: 50.0,
          transactionTime: now.toIso8601String(),
        ),
      );

      // Act
      final incomeTotalResult = await repository.getTotalByType(
        TransactionType.income,
      );
      final expenseTotalResult = await repository.getTotalByType(
        TransactionType.expense,
      );

      // Assert
      final incomeTotal = incomeTotalResult.when(
        success: (total) => total,
        failure: (error) => fail('Failed to get income total: $error'),
      );
      final expenseTotal = expenseTotalResult.when(
        success: (total) => total,
        failure: (error) => fail('Failed to get expense total: $error'),
      );

      expect(incomeTotal, 300.0);
      expect(expenseTotal, 50.0);
    });

    test('calculates total by type with date range', () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.income,
          amount: 100.0,
          transactionTime: yesterday.toIso8601String(),
        ),
      );
      await repository.createTransaction(
        FinanceTransaction(
          type: TransactionType.income,
          amount: 200.0,
          transactionTime: now.toIso8601String(),
        ),
      );

      // Act
      final todayTotalResult = await repository.getTotalByType(
        TransactionType.income,
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 1)),
      );

      // Assert
      final todayTotal = todayTotalResult.when(
        success: (total) => total,
        failure: (error) => fail('Failed to get today total: $error'),
      );

      expect(todayTotal, 200.0);
    });
  });
}
