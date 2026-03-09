import 'dart:developer' as developer;
import 'package:telegraph/models/finance_transaction.dart';

/// Validates if a string is a valid ISO 8601 date format
bool isValidIso8601(String str) {
  try {
    DateTime.parse(str);
    return true;
  } catch (e) {
    return false;
  }
}

/// Converts a string to TransactionType enum
TransactionType parseTransactionType(String typeStr) {
  return typeStr.toLowerCase() == 'expense'
      ? TransactionType.expense
      : TransactionType.income;
}

/// Gets the label for a TransactionType
String transactionTypeLabel(TransactionType type) {
  return type == TransactionType.income ? 'Income' : 'Expense';
}

/// Generic error handler for tool execution
Future<String> handleToolError(
  String context,
  Future<String> Function() action,
) async {
  try {
    return await action();
  } catch (e, stackTrace) {
    developer.log('Error $context: $e', stackTrace: stackTrace);
    return 'Error $context: $e';
  }
}
