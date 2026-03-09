import 'package:test/test.dart';
import 'package:telegraph/core/errors/exceptions.dart';

void main() {
  group('AppException', () {
    test('should be implemented by DatabaseException', () {
      final exception = DatabaseException('Test error');
      expect(exception is AppException, isTrue);
      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('should include message in toString', () {
      final exception = DatabaseException('Test error');
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('DatabaseException'));
    });
  });

  group('DatabaseException', () {
    test('should create with message', () {
      final exception = DatabaseException('DB error');
      expect(exception.message, 'DB error');
      expect(exception.code, isNull);
    });

    test('should create with code', () {
      final exception = DatabaseException(
        'DB error',
        code: 'DB_CONNECTION_FAILED',
      );
      expect(exception.code, 'DB_CONNECTION_FAILED');
    });
  });

  group('AiServiceException', () {
    test('should create with message', () {
      final exception = AiServiceException('AI error');
      expect(exception.message, 'AI error');
    });

    test('should include original error', () {
      final exception = AiServiceException(
        'AI error',
        originalError: 'Connection timeout',
      );
      expect(exception.originalError, 'Connection timeout');
    });
  });

  group('ValidationException', () {
    test('should create with message', () {
      final exception = ValidationException('Invalid input');
      expect(exception.message, 'Invalid input');
      expect(exception.fieldErrors, isNull);
    });

    test('should create with field errors', () {
      final exception = ValidationException(
        'Validation failed',
        fieldErrors: {
          'email': 'Invalid email format',
          'password': 'Password too short',
        },
      );
      expect(exception.fieldErrors!.length, 2);
      expect(exception.fieldErrors!['email'], 'Invalid email format');
    });

    test('toString includes field errors', () {
      final exception = ValidationException(
        'Validation failed',
        fieldErrors: {'field': 'error message'},
      );
      final toString = exception.toString();
      expect(toString, contains('field: error message'));
    });
  });

  group('ToolException', () {
    test('should create with tool name and message', () {
      final exception = ToolException('add_transaction', 'Invalid amount');
      expect(exception.toolName, 'add_transaction');
      expect(exception.message, 'Invalid amount');
    });

    test('toString includes tool name', () {
      final exception = ToolException('delete_session', 'Session not found');
      expect(exception.toString(), contains('tool: delete_session'));
      expect(exception.toString(), contains('Session not found'));
    });
  });

  group('NotFoundException', () {
    test('should create with message', () {
      final exception = NotFoundException('Resource not found');
      expect(exception.message, 'Resource not found');
    });
  });

  group('BusinessLogicException', () {
    test('should create with message', () {
      final exception = BusinessLogicException('Business rule violated');
      expect(exception.message, 'Business rule violated');
    });
  });
}

class OriginalError {}
