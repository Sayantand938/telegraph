/// Custom exception hierarchy for the Telegraph application.
/// Provides typed exceptions that enable precise error handling and reporting.

/// Base exception for all application-specific errors.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer('${runtimeType.toString()}');
    if (code != null) {
      buffer.write('(code: $code)');
    }
    buffer.write(': $message');
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a database operation fails.
class DatabaseException extends AppException {
  DatabaseException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

/// Exception thrown when the AI service is unavailable or returns an error.
class AiServiceException extends AppException {
  AiServiceException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

/// Exception thrown when input validation fails.
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    String message, {
    String? code,
    this.fieldErrors,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() {
    final base = super.toString();
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final errors = fieldErrors!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return '$base\nField errors: $errors';
    }
    return base;
  }
}

/// Exception thrown when a tool execution fails.
class ToolException extends AppException {
  final String toolName;

  ToolException(
    this.toolName,
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() {
    return '${runtimeType.toString()}(tool: $toolName): $message';
  }
}

/// Exception thrown when a resource is not found.
class NotFoundException extends AppException {
  NotFoundException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

/// Exception thrown when a user is not authorized to perform an action.
class UnauthorizedException extends AppException {
  UnauthorizedException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

/// Exception thrown when a business rule is violated.
class BusinessLogicException extends AppException {
  BusinessLogicException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}
