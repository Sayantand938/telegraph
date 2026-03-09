// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:telegraph/services/tools/tool_definitions.dart';
import 'package:telegraph/services/tools/tool_enhancements.dart';
import 'package:telegraph/services/tools/tool_service.dart';

void main() {
  group('ToolParameterValidator', () {
    test('should validate required parameters', () {
      final param = ToolParameter(
        name: 'test_param',
        type: 'string',
        description: 'A test parameter',
        required: true,
      );

      // Missing required parameter
      final result = ToolParameterValidator.validate(
        param.name,
        null,
        param.type,
        required: param.required,
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('missing'));

      // Provided required parameter
      final validResult = ToolParameterValidator.validate(
        param.name,
        'value',
        param.type,
        required: param.required,
      );
      expect(validResult.isValid, true);
    });

    test('should validate string type', () {
      final param = ToolParameter(
        name: 'name',
        type: 'string',
        description: 'Name',
        required: true,
      );

      // Valid string
      var result = ToolParameterValidator.validate(
        param.name,
        'test',
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Invalid type
      result = ToolParameterValidator.validate(
        param.name,
        123,
        param.type,
        required: param.required,
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('string'));
    });

    test('should validate integer type', () {
      final param = ToolParameter(
        name: 'count',
        type: 'integer',
        description: 'Count',
        required: true,
      );

      // Valid integer
      var result = ToolParameterValidator.validate(
        param.name,
        42,
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Valid string that can be parsed
      result = ToolParameterValidator.validate(
        param.name,
        '123',
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Invalid string
      result = ToolParameterValidator.validate(
        param.name,
        'abc',
        param.type,
        required: param.required,
      );
      expect(result.isValid, false);
    });

    test('should validate number type', () {
      final param = ToolParameter(
        name: 'amount',
        type: 'number',
        description: 'Amount',
        required: true,
      );

      // Valid number
      var result = ToolParameterValidator.validate(
        param.name,
        42.5,
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Valid integer (num includes int)
      result = ToolParameterValidator.validate(
        param.name,
        42,
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Valid string
      result = ToolParameterValidator.validate(
        param.name,
        '3.14',
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);
    });

    test('should validate boolean type', () {
      final param = ToolParameter(
        name: 'active',
        type: 'boolean',
        description: 'Active flag',
        required: true,
      );

      // Valid boolean
      var result = ToolParameterValidator.validate(
        param.name,
        true,
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Valid string "true"
      result = ToolParameterValidator.validate(
        param.name,
        'true',
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Valid string "false"
      result = ToolParameterValidator.validate(
        param.name,
        'false',
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Invalid string
      result = ToolParameterValidator.validate(
        param.name,
        'yes',
        param.type,
        required: param.required,
      );
      expect(result.isValid, false);
    });

    test('should validate date/time strings', () {
      final param = ToolParameter(
        name: 'timestamp',
        type: 'string',
        description: 'Timestamp',
        required: true,
      );

      // Valid ISO 8601 - string type accepts any string
      var result = ToolParameterValidator.validate(
        param.name,
        '2025-01-15T10:30:00',
        param.type,
        required: param.required,
      );
      expect(result.isValid, true);

      // Any string is valid for string type
      result = ToolParameterValidator.validate(
        param.name,
        'not a date',
        param.type,
        required: param.required,
      );
      expect(result.isValid, true); // String type accepts any string
    });

    test('should validate all parameters for a tool', () {
      final parameters = [
        ToolParameter(
          name: 'type',
          type: 'string',
          description: 'Transaction type',
          required: true,
        ),
        ToolParameter(
          name: 'amount',
          type: 'number',
          description: 'Amount',
          required: true,
        ),
        ToolParameter(
          name: 'note',
          type: 'string',
          description: 'Note',
          required: false,
        ),
      ];

      // Valid args
      final validArgs = {'type': 'income', 'amount': 100.0};
      final validResults = ToolParameterValidator.validateAll(
        parameters,
        validArgs,
      );
      expect(ToolParameterValidator.areAllValid(validResults), true);
      expect(ToolParameterValidator.getInvalid(validResults).isEmpty, true);

      // Missing required parameter
      final invalidArgs = {'amount': 100.0};
      final invalidResults = ToolParameterValidator.validateAll(
        parameters,
        invalidArgs,
      );
      expect(ToolParameterValidator.areAllValid(invalidResults), false);
      expect(ToolParameterValidator.getInvalid(invalidResults).length, 1);
    });
  });

  group('SimpleToolCache', () {
    test('should store and retrieve cached values', () {
      final cache = SimpleToolCache();
      final key = {
        'tool': 'test_tool',
        'args': {'param': 'value'},
      };
      const testValue = 'cached result';

      cache.setInCache(key, testValue, const Duration(seconds: 60));
      final cached = cache.getFromCache(key);

      expect(cached, testValue);
    });

    test('should return null for expired cache entries', () async {
      final cache = SimpleToolCache();
      final key = {
        'tool': 'test_tool',
        'args': {'param': 'value'},
      };
      const testValue = 'cached result';

      cache.setInCache(key, testValue, const Duration(milliseconds: 10));

      // Wait for cache to expire
      await Future.delayed(const Duration(milliseconds: 20));

      final cached = cache.getFromCache(key);
      expect(cached, isNull);
    });

    test('should clean up expired entries', () async {
      final cache = SimpleToolCache();

      // Add expired entry
      final expiredKey = {'tool': 'expired', 'args': {}};
      cache.setInCache(expiredKey, 'expired', const Duration(milliseconds: 50));

      // Add valid entry
      final validKey = {'tool': 'valid', 'args': {}};
      cache.setInCache(validKey, 'valid', const Duration(seconds: 60));

      // Wait for first entry to expire
      await Future.delayed(const Duration(milliseconds: 100));

      cache.cleanup();

      expect(cache.getFromCache(expiredKey), isNull);
      expect(cache.getFromCache(validKey), 'valid');
    });

    test('should report cache statistics', () {
      final cache = SimpleToolCache();

      cache.setInCache(
        {'tool': 't1', 'args': {}},
        'value1',
        const Duration(seconds: 60),
      );
      cache.setInCache(
        {'tool': 't2', 'args': {}},
        'value2',
        const Duration(seconds: 60),
      );

      final stats = cache.getStats();
      expect(stats['totalEntries'], 2);
      expect(stats['activeEntries'], 2);
      expect(stats['expiredEntries'], 0);
    });
  });

  group('ToolExecutionMetrics', () {
    test('should serialize to JSON', () {
      final now = DateTime.now();
      final metrics = ToolExecutionMetrics(
        toolName: 'test_tool',
        startTime: now,
        endTime: now,
        executionTimeMs: 100,
        success: true,
        arguments: {'param': 'value'},
      );

      final json = metrics.toJson();
      expect(json['toolName'], equals('test_tool'));
      expect(json['executionTimeMs'], equals(100));
      expect(json['success'], equals(true));
      expect(json['arguments'], equals({'param': 'value'}));
    });
  });

  group('ValidationResult', () {
    test('should create valid result', () {
      final result = ValidationResult.valid('test_param');
      expect(result.isValid, true);
      expect(result.errorMessage, isNull);
    });

    test('should create invalid result', () {
      final result = ValidationResult.invalid('test_param', 'Error message');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Error message');
    });

    test('should format toString correctly', () {
      var result = ValidationResult.valid('param');
      expect(result.toString(), '✓ param');

      result = ValidationResult.invalid('param', 'Invalid');
      expect(result.toString(), '✗ param: Invalid');
    });

    test('should handle empty parameter name', () {
      final result = ValidationResult.valid('');
      expect(result.isValid, true);
      expect(result.parameterName, '');
    });
  });
}
