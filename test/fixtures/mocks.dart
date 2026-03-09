import 'package:mocktail/mocktail.dart';
import 'package:telegraph/services/database/i_session_database.dart';
import 'package:telegraph/services/database/i_finance_database.dart';
import 'package:telegraph/models/session.dart';
import 'package:telegraph/models/finance_transaction.dart';

class MockSessionDatabase extends Mock implements ISessionDatabase {}

class MockFinanceDatabase extends Mock implements IFinanceDatabase {}

/// Helper class to create common session data for testing
class SessionTestHelper {
  static Session createSession({
    int? id,
    String startTime = '2025-01-15T10:30:00.000Z',
    String? endTime,
    String? notes,
  }) {
    return Session(
      id: id,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
    );
  }

  static Map<String, dynamic> toMap(Session session) {
    return {
      'id': session.id,
      'start_time': session.startTime,
      'end_time': session.endTime,
      'notes': session.notes,
    };
  }
}

/// Helper class to create common finance transaction data for testing
class FinanceTransactionTestHelper {
  static FinanceTransaction createTransaction({
    int? id,
    required TransactionType type,
    double amount = 100.0,
    String transactionTime = '2025-01-15T12:00:00.000Z',
    String? note,
  }) {
    return FinanceTransaction(
      id: id,
      type: type,
      amount: amount,
      transactionTime: transactionTime,
      note: note,
    );
  }

  static Map<String, dynamic> toMap(FinanceTransaction transaction) {
    return {
      'id': transaction.id,
      'type': transaction.type.name,
      'amount': transaction.amount,
      'transaction_time': transaction.transactionTime,
      'note': transaction.note,
    };
  }
}
