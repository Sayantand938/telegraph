import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/services/repositories/i_finance_repository.dart';
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
      final id = await repository.createTransaction(transaction);
      final retrieved = await repository.getTransaction(id!);

      // Assert
      expect(retrieved, isNotNull);
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
      final id = await repository.createTransaction(transaction);

      // Act
      final updated = transaction.copyWith(
        id: id,
        amount: 75.0,
        note: 'Updated note',
      );
      await repository.updateTransaction(updated);
      final retrieved = await repository.getTransaction(id!);

      // Assert
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
      final id = await repository.createTransaction(transaction);

      // Act
      await repository.deleteTransaction(id!);
      final retrieved = await repository.getTransaction(id);

      // Assert
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
      final all = await repository.getAllTransactions();

      // Assert
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
      final income = await repository.getTransactionsByType(
        TransactionType.income,
      );
      final expenses = await repository.getTransactionsByType(
        TransactionType.expense,
      );

      // Assert
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
      final inRange = await repository.getTransactionsByDateRange(
        now.subtract(const Duration(hours: 1)),
        tomorrow,
      );

      // Assert
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
      final incomeTotal = await repository.getTotalByType(
        TransactionType.income,
      );
      final expenseTotal = await repository.getTotalByType(
        TransactionType.expense,
      );

      // Assert
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
      final todayTotal = await repository.getTotalByType(
        TransactionType.income,
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 1)),
      );

      // Assert
      expect(todayTotal, 200.0);
    });
  });
}
