// ignore_for_file: unused_import, unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:telegraph/services/tools/finance_tools.dart';
import 'package:telegraph/services/tools/tool_definitions.dart';
import 'package:telegraph/services/database/i_finance_database.dart';
import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/core/errors/exceptions.dart';
import '../../fixtures/sample_data.dart';
import '../../fixtures/mocks.dart';

void main() {
  late MockFinanceDatabase mockFinanceDb;
  late List<Tool> financeTools;

  setUpAll(() {
    registerFallbackValue(
      FinanceTransaction(
        id: 0,
        type: TransactionType.income,
        amount: 0.0,
        transactionTime: '',
        note: null,
      ),
    );
    registerFallbackValue(DateTime(2025, 1, 1));
  });

  setUp(() {
    mockFinanceDb = MockFinanceDatabase();
    financeTools = getFinanceTools(mockFinanceDb);
  });

  group('Finance Tools', () {
    group('add_transaction', () {
      test('adds income transaction successfully', () async {
        // Arrange
        when(
          () => mockFinanceDb.createTransaction(any()),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'add_transaction')
            .execute({
              'type': 'income',
              'amount': 150.0,
              'note': 'Freelance payment',
            });

        // Assert
        expect(result, contains('Income transaction recorded'));
        expect(result, contains('ID: 1'));
        expect(result, contains('\$150.00'));
      });

      test('adds expense transaction successfully', () async {
        // Arrange
        when(
          () => mockFinanceDb.createTransaction(any()),
        ).thenAnswer((_) async => 2);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'add_transaction')
            .execute({'type': 'expense', 'amount': 75.50});

        // Assert
        expect(result, contains('Expense transaction recorded'));
        expect(result, contains('ID: 2'));
        expect(result, contains('\$75.50'));
      });

      test('validates amount is positive', () async {
        // Act & Assert
        expect(
          () async => await financeTools
              .firstWhere((t) => t.name == 'add_transaction')
              .execute({'type': 'income', 'amount': -50.0}),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'INVALID_AMOUNT',
            ),
          ),
        );
      });

      test('validates transaction_time format when provided', () async {
        // Act & Assert
        expect(
          () async => await financeTools
              .firstWhere((t) => t.name == 'add_transaction')
              .execute({
                'type': 'income',
                'amount': 100.0,
                'transaction_time': 'invalid-date',
              }),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'INVALID_DATE_FORMAT',
            ),
          ),
        );
      });

      test('uses current time when transaction_time not provided', () async {
        // Arrange
        when(
          () => mockFinanceDb.createTransaction(any()),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'add_transaction')
            .execute({'type': 'expense', 'amount': 25.0});

        // Assert
        expect(result, contains('Expense transaction recorded'));
      });
    });

    group('list_transactions', () {
      test('lists all transactions when no filter', () async {
        // Arrange
        final transactions = [
          FinanceTransactionFixtures.incomeTransaction(id: 1, amount: 100.0),
          FinanceTransactionFixtures.expenseTransaction(id: 2, amount: 50.0),
        ];
        when(
          () => mockFinanceDb.getAllTransactions(),
        ).thenAnswer((_) async => transactions);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'list_transactions')
            .execute({});

        // Assert
        expect(result, contains('Financial Transactions:'));
        expect(result, contains('ID 1: [Income]'));
        expect(result, contains('ID 2: [Expense]'));
        expect(result, contains('Total Income: +\$100.00'));
        expect(result, contains('Total Expense: -\$50.00'));
      });

      test('filters by type=income', () async {
        // Arrange
        final transactions = [
          FinanceTransactionTestHelper.createTransaction(
            type: TransactionType.income,
          ),
          FinanceTransactionTestHelper.createTransaction(
            type: TransactionType.expense,
          ),
        ];
        when(
          () => mockFinanceDb.getTransactionsByType(TransactionType.income),
        ).thenAnswer((_) async => [transactions[0]]);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'list_transactions')
            .execute({'type': 'income'});

        // Assert
        expect(result, contains('[Income]'));
        expect(result, isNot(contains('[Expense]')));
      });

      test('filters by type=expense', () async {
        // Arrange
        final transactions = [
          FinanceTransactionTestHelper.createTransaction(
            type: TransactionType.income,
          ),
          FinanceTransactionTestHelper.createTransaction(
            type: TransactionType.expense,
          ),
        ];
        when(
          () => mockFinanceDb.getTransactionsByType(TransactionType.expense),
        ).thenAnswer((_) async => [transactions[1]]);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'list_transactions')
            .execute({'type': 'expense'});

        // Assert
        expect(result, contains('[Expense]'));
        expect(result, isNot(contains('[Income]')));
      });

      test('filters by date range', () async {
        // Arrange
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        final transactions = [
          FinanceTransactionFixtures.incomeTransaction(
            id: 1,
            transactionTime: '2025-01-15T12:00:00Z',
          ),
        ];
        when(
          () => mockFinanceDb.getTransactionsByDateRange(any(), any()),
        ).thenAnswer((_) async => transactions);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'list_transactions')
            .execute({
              'start_date': '2025-01-01T00:00:00Z',
              'end_date': '2025-01-31T23:59:59Z',
            });

        // Assert
        expect(result, contains('Financial Transactions:'));
        expect(result, contains('ID 1:'));
      });

      test('returns "No transactions found" when empty', () async {
        // Arrange
        when(
          () => mockFinanceDb.getAllTransactions(),
        ).thenAnswer((_) async => []);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'list_transactions')
            .execute({});

        // Assert
        expect(result, contains('No transactions found'));
      });
    });

    group('get_transaction', () {
      test('returns transaction details when found', () async {
        // Arrange
        final transaction = FinanceTransactionFixtures.incomeTransaction(
          id: 1,
          amount: 200.0,
          note: 'Bonus',
        );
        when(
          () => mockFinanceDb.getTransaction(1),
        ).thenAnswer((_) async => transaction);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'get_transaction')
            .execute({'transaction_id': 1});

        // Assert
        expect(result, contains('Transaction 1:'));
        expect(result, contains('Type: Income'));
        expect(result, contains('\$200.00'));
        expect(result, contains('Bonus'));
      });

      test(
        'throws NotFoundException when transaction does not exist',
        () async {
          // Arrange
          when(
            () => mockFinanceDb.getTransaction(999),
          ).thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () async => await financeTools
                .firstWhere((t) => t.name == 'get_transaction')
                .execute({'transaction_id': 999}),
            throwsA(
              isA<NotFoundException>().having(
                (e) => e.code,
                'code',
                'TRANSACTION_NOT_FOUND',
              ),
            ),
          );
        },
      );
    });

    group('delete_transaction', () {
      test('returns success message when transaction deleted', () async {
        // Arrange
        when(
          () => mockFinanceDb.deleteTransaction(1),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'delete_transaction')
            .execute({'transaction_id': 1});

        // Assert
        expect(result, contains('Transaction 1 deleted successfully'));
      });

      test(
        'throws NotFoundException when transaction does not exist',
        () async {
          // Arrange
          when(
            () => mockFinanceDb.deleteTransaction(999),
          ).thenAnswer((_) async => 0);

          // Act & Assert
          expect(
            () async => await financeTools
                .firstWhere((t) => t.name == 'delete_transaction')
                .execute({'transaction_id': 999}),
            throwsA(
              isA<NotFoundException>().having(
                (e) => e.code,
                'code',
                'TRANSACTION_NOT_FOUND',
              ),
            ),
          );
        },
      );
    });

    group('update_transaction', () {
      test('updates transaction successfully', () async {
        // Arrange
        final existing = FinanceTransactionFixtures.incomeTransaction(
          id: 1,
          amount: 100.0,
        );
        when(
          () => mockFinanceDb.getTransaction(1),
        ).thenAnswer((_) async => existing);
        when(
          () => mockFinanceDb.updateTransaction(any()),
        ).thenAnswer((_) async => 1);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'update_transaction')
            .execute({
              'transaction_id': 1,
              'amount': 150.0,
              'note': 'Updated note',
            });

        // Assert
        expect(result, contains('Transaction 1 updated successfully'));
      });

      test('throws NotFoundException when transaction not found', () async {
        // Arrange
        when(
          () => mockFinanceDb.getTransaction(999),
        ).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () async => await financeTools
              .firstWhere((t) => t.name == 'update_transaction')
              .execute({'transaction_id': 999, 'amount': 100.0}),
          throwsA(
            isA<NotFoundException>().having(
              (e) => e.code,
              'code',
              'TRANSACTION_NOT_FOUND',
            ),
          ),
        );
      });

      test('validates amount is positive when provided', () async {
        // Arrange
        final existing = FinanceTransactionFixtures.incomeTransaction(id: 1);
        when(
          () => mockFinanceDb.getTransaction(1),
        ).thenAnswer((_) async => existing);

        // Act & Assert
        expect(
          () async => await financeTools
              .firstWhere((t) => t.name == 'update_transaction')
              .execute({'transaction_id': 1, 'amount': -50.0}),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'INVALID_AMOUNT',
            ),
          ),
        );
      });

      test('validates transaction_time format when provided', () async {
        // Arrange
        final existing = FinanceTransactionFixtures.incomeTransaction(id: 1);
        when(
          () => mockFinanceDb.getTransaction(1),
        ).thenAnswer((_) async => existing);

        // Act & Assert
        expect(
          () async => await financeTools
              .firstWhere((t) => t.name == 'update_transaction')
              .execute({
                'transaction_id': 1,
                'transaction_time': 'invalid-date',
              }),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'INVALID_DATE_FORMAT',
            ),
          ),
        );
      });
    });

    group('get_financial_summary', () {
      test('returns summary for all transactions', () async {
        // Arrange
        when(
          () => mockFinanceDb.getTotalByType(TransactionType.income),
        ).thenAnswer((_) async => 500.0);
        when(
          () => mockFinanceDb.getTotalByType(TransactionType.expense),
        ).thenAnswer((_) async => 200.0);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'get_financial_summary')
            .execute({'period': 'all'});

        // Assert
        expect(result, contains('Financial Summary'));
        expect(result, contains('Income: +\$500.00'));
        expect(result, contains('Expenses: -\$200.00'));
        expect(result, contains('Net Balance: \$300.00'));
      });

      test('returns summary for today', () async {
        // Arrange
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.income,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 50.0);
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.expense,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 25.0);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'get_financial_summary')
            .execute({'period': 'today'});

        // Assert
        expect(result, contains('Financial Summary (today)'));
      });

      test('returns summary for week', () async {
        // Arrange
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.income,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 300.0);
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.expense,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 150.0);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'get_financial_summary')
            .execute({'period': 'week'});

        // Assert
        expect(result, contains('Financial Summary (week)'));
      });

      test('returns summary for month', () async {
        // Arrange
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.income,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 1000.0);
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.expense,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 500.0);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'get_financial_summary')
            .execute({'period': 'month'});

        // Assert
        expect(result, contains('Financial Summary (month)'));
      });

      test('returns summary for year', () async {
        // Arrange
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.income,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 5000.0);
        when(
          () => mockFinanceDb.getTotalByType(
            TransactionType.expense,
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => 2500.0);

        // Act
        final result = await financeTools
            .firstWhere((t) => t.name == 'get_financial_summary')
            .execute({'period': 'year'});

        // Assert
        expect(result, contains('Financial Summary (year)'));
      });
    });
  });
}
