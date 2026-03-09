import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/models/finance_transaction.dart';
import '../../fixtures/sample_data.dart';

void main() {
  group('FinanceTransaction Model', () {
    group('Constructor', () {
      test('creates income transaction correctly', () {
        final transaction = FinanceTransactionFixtures.incomeTransaction();
        expect(transaction.type, TransactionType.income);
        expect(transaction.amount, 100.0);
        expect(transaction.transactionTime, isNotNull);
        expect(transaction.note, isNull);
      });

      test('creates expense transaction correctly', () {
        final transaction = FinanceTransactionFixtures.expenseTransaction();
        expect(transaction.type, TransactionType.expense);
        expect(transaction.amount, 50.0);
      });

      test('creates transaction with all fields', () {
        final transaction = FinanceTransactionFixtures.salary();
        expect(transaction.id, isNull);
        expect(transaction.type, TransactionType.income);
        expect(transaction.amount, 5000.0);
        expect(transaction.note, 'Monthly salary');
      });
    });

    group('toMap', () {
      test('converts income transaction to map correctly', () {
        final transaction = FinanceTransactionFixtures.incomeTransaction(
          id: 1,
          amount: 150.0,
          transactionTime: '2025-01-15T12:00:00Z',
          note: 'Freelance payment',
        );
        final map = transaction.toMap();

        expect(map['id'], 1);
        expect(map['type'], 'income');
        expect(map['amount'], 150.0);
        expect(map['transaction_time'], '2025-01-15T12:00:00Z');
        expect(map['note'], 'Freelance payment');
      });

      test('converts expense transaction to map correctly', () {
        final transaction = FinanceTransactionFixtures.expenseTransaction(
          id: 2,
          amount: 75.50,
        );
        final map = transaction.toMap();

        expect(map['id'], 2);
        expect(map['type'], 'expense');
        expect(map['amount'], 75.50);
      });

      test('handles null note', () {
        final transaction = FinanceTransactionFixtures.incomeTransaction(
          note: null,
        );
        final map = transaction.toMap();

        expect(map['note'], isNull);
      });
    });

    group('fromMap', () {
      test('creates income transaction from map correctly', () {
        final map = FinanceTransactionFixtures.toMapFixture(
          id: 1,
          type: TransactionType.income,
          amount: 200.0,
          transactionTime: '2025-01-15T14:30:00Z',
          note: 'Bonus',
        );
        final transaction = FinanceTransaction.fromMap(map);

        expect(transaction.id, 1);
        expect(transaction.type, TransactionType.income);
        expect(transaction.amount, 200.0);
        expect(transaction.transactionTime, '2025-01-15T14:30:00Z');
        expect(transaction.note, 'Bonus');
      });

      test('creates expense transaction from map correctly', () {
        final map = FinanceTransactionFixtures.toMapFixture(
          id: 2,
          type: TransactionType.expense,
          amount: 99.99,
          transactionTime: '2025-01-15T10:00:00Z',
        );
        final transaction = FinanceTransaction.fromMap(map);

        expect(transaction.id, 2);
        expect(transaction.type, TransactionType.expense);
        expect(transaction.amount, 99.99);
      });

      test('defaults to income when type not found', () {
        final map = {
          'id': 1,
          'type': 'unknown',
          'amount': 100.0,
          'transaction_time': '2025-01-15T12:00:00Z',
        };
        final transaction = FinanceTransaction.fromMap(map);

        expect(transaction.type, TransactionType.income);
      });

      test('handles null note', () {
        final map = FinanceTransactionFixtures.toMapFixture(
          type: TransactionType.income,
          note: null,
        );
        final transaction = FinanceTransaction.fromMap(map);

        expect(transaction.note, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with all fields', () {
        final original = FinanceTransactionFixtures.coffee();
        final copy = original.copyWith(
          id: 1,
          amount: 5.99,
          note: 'Updated note',
        );

        expect(copy.id, 1);
        expect(copy.type, original.type);
        expect(copy.amount, 5.99);
        expect(copy.transactionTime, original.transactionTime);
        expect(copy.note, 'Updated note');
      });

      test('preserves original when no parameters provided', () {
        final original = FinanceTransactionFixtures.rent();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.type, original.type);
        expect(copy.amount, original.amount);
        expect(copy.transactionTime, original.transactionTime);
        expect(copy.note, original.note);
      });

      test('updates only specified fields', () {
        final original = FinanceTransactionFixtures.salary();
        final copy = original.copyWith(amount: 5500.0);

        expect(copy.id, original.id);
        expect(copy.type, original.type);
        expect(copy.amount, 5500.0);
        expect(copy.transactionTime, original.transactionTime);
        expect(copy.note, original.note);
      });
    });

    group('Enum Serialization', () {
      test('TransactionType.income has correct name', () {
        expect(TransactionType.income.name, 'income');
      });

      test('TransactionType.expense has correct name', () {
        expect(TransactionType.expense.name, 'expense');
      });

      test('fromMap correctly parses income from string', () {
        final map = FinanceTransactionFixtures.toMapFixture(
          type: TransactionType.income,
        );
        final transaction = FinanceTransaction.fromMap(map);
        expect(transaction.type, TransactionType.income);
      });

      test('fromMap correctly parses expense from string', () {
        final map = FinanceTransactionFixtures.toMapFixture(
          type: TransactionType.expense,
        );
        final transaction = FinanceTransaction.fromMap(map);
        expect(transaction.type, TransactionType.expense);
      });
    });

    group('Equality', () {
      test('two transactions with same data are equal', () {
        final tx1 = FinanceTransactionFixtures.incomeTransaction(
          id: 1,
          amount: 100.0,
          transactionTime: '2025-01-15T12:00:00Z',
          note: 'Test',
        );
        final tx2 = FinanceTransaction(
          id: 1,
          type: TransactionType.income,
          amount: 100.0,
          transactionTime: '2025-01-15T12:00:00Z',
          note: 'Test',
        );

        expect(tx1, equals(tx2));
      });

      test('transactions with different data are not equal', () {
        final tx1 = FinanceTransactionFixtures.incomeTransaction();
        final tx2 = FinanceTransactionFixtures.expenseTransaction();

        expect(tx1, isNot(equals(tx2)));
      });

      test('transactions with different amounts are not equal', () {
        final tx1 = FinanceTransactionFixtures.incomeTransaction(amount: 100.0);
        final tx2 = FinanceTransactionFixtures.incomeTransaction(amount: 200.0);

        expect(tx1, isNot(equals(tx2)));
      });
    });
  });
}
