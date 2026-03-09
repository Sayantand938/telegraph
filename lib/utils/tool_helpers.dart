import 'package:telegraph/models/finance_transaction.dart';
import 'package:telegraph/core/errors/exceptions.dart';

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

/// Throws a ValidationException with the given message
Never throwValidationError(String message, {String? code}) {
  throw ValidationException(message, code: code);
}

/// Throws a ToolException with the given message
Never throwToolError(
  String toolName,
  String message, {
  String? code,
  dynamic originalError,
}) {
  throw ToolException(
    toolName,
    message,
    code: code,
    originalError: originalError,
  );
}
