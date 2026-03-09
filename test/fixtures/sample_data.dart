import 'package:telegraph/models/session.dart';
import 'package:telegraph/models/finance_transaction.dart';

/// Test fixtures for Session model
class SessionFixtures {
  static Session validSession({
    int? id,
    String? startTime,
    String? endTime,
    String? notes,
  }) {
    return Session(
      id: id,
      startTime: startTime ?? '2025-01-15T10:30:00.000Z',
      endTime: endTime,
      notes: notes,
    );
  }

  static Map<String, dynamic> toMapFixture({
    int? id,
    String? startTime,
    String? endTime,
    String? notes,
  }) {
    return {
      'id': id,
      'start_time': startTime ?? '2025-01-15T10:30:00.000Z',
      'end_time': endTime,
      'notes': notes,
    };
  }

  static Session activeSession() {
    return validSession(notes: 'Working on project');
  }

  static Session completedSession() {
    return validSession(
      endTime: '2025-01-15T17:30:00.000Z',
      notes: 'Completed work',
    );
  }

  static Session multiDaySession() {
    return validSession(
      startTime: '2025-01-15T10:00:00.000Z',
      endTime: '2025-01-17T15:00:00.000Z',
      notes: 'Long project',
    );
  }
}

/// Test fixtures for FinanceTransaction model
class FinanceTransactionFixtures {
  static FinanceTransaction incomeTransaction({
    int? id,
    double? amount,
    String? transactionTime,
    String? note,
  }) {
    return FinanceTransaction(
      id: id,
      type: TransactionType.income,
      amount: amount ?? 100.0,
      transactionTime: transactionTime ?? '2025-01-15T12:00:00.000Z',
      note: note,
    );
  }

  static FinanceTransaction expenseTransaction({
    int? id,
    double? amount,
    String? transactionTime,
    String? note,
  }) {
    return FinanceTransaction(
      id: id,
      type: TransactionType.expense,
      amount: amount ?? 50.0,
      transactionTime: transactionTime ?? '2025-01-15T12:00:00.000Z',
      note: note,
    );
  }

  static Map<String, dynamic> toMapFixture({
    int? id,
    required TransactionType type,
    double? amount,
    String? transactionTime,
    String? note,
  }) {
    return {
      'id': id,
      'type': type.name,
      'amount': amount ?? 100.0,
      'transaction_time': transactionTime ?? '2025-01-15T12:00:00.000Z',
      'note': note,
    };
  }

  static FinanceTransaction salary() {
    return incomeTransaction(amount: 5000.0, note: 'Monthly salary');
  }

  static FinanceTransaction coffee() {
    return expenseTransaction(amount: 4.50, note: 'Morning coffee');
  }

  static FinanceTransaction rent() {
    return expenseTransaction(amount: 1200.0, note: 'Monthly rent');
  }
}
