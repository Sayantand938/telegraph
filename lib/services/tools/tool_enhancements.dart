// ignore_for_file: unnecessary_cast, unused_local_variable

import 'dart:async';
import 'tool_definitions.dart';
import 'tool_service.dart';
import 'package:telegraph/core/errors/exceptions.dart';

/// Custom validation function type
typedef ValidationRule<T> = String? Function(T value);

/// Enum for supported parameter types with type safety
enum ToolParameterType {
  string,
  integer,
  number,
  boolean,
  array,
  object,
  dateTime, // ISO 8601 string
}

/// Validation result for a single parameter
class ValidationResult {
  final String parameterName;
  final bool isValid;
  final String? errorMessage;

  ValidationResult._(this.parameterName, this.isValid, this.errorMessage);

  factory ValidationResult.valid(String parameterName) {
    return ValidationResult._(parameterName, true, null);
  }

  factory ValidationResult.invalid(String parameterName, String errorMessage) {
    return ValidationResult._(parameterName, false, errorMessage);
  }

  @override
  String toString() {
    if (isValid) {
      return '✓ $parameterName';
    }
    return '✗ $parameterName: $errorMessage';
  }
}

/// Tool parameter validator - works with legacy ToolParameter
class ToolParameterValidator {
  /// Validate a single parameter value
  static ValidationResult validate(
    String name,
    dynamic value,
    String typeStr, {
    bool required = false,
  }) {
    // Check if required
    if (required && value == null) {
      return ValidationResult.invalid(name, 'Required parameter is missing');
    }

    if (value == null) {
      return ValidationResult.valid(name);
    }

    // Type validation
    final typeValidation = _validateType(name, value, typeStr);
    if (!typeValidation.isValid) {
      return typeValidation;
    }

    return ValidationResult.valid(name);
  }

  /// Validate all parameters for a tool
  static Map<String, ValidationResult> validateAll(
    List<ToolParameter> parameters,
    Map<String, dynamic> args,
  ) {
    final results = <String, ValidationResult>{};

    for (final param in parameters) {
      final value = args[param.name];
      results[param.name] = validate(
        param.name,
        value,
        param.type,
        required: param.required,
      );
    }

    return results;
  }

  /// Get all invalid parameters
  static List<ValidationResult> getInvalid(
    Map<String, ValidationResult> results,
  ) {
    return results.values.where((r) => !r.isValid).toList();
  }

  /// Check if all parameters are valid
  static bool areAllValid(Map<String, ValidationResult> results) {
    return results.values.every((r) => r.isValid);
  }

  static ValidationResult _validateType(
    String paramName,
    dynamic value,
    String typeStr,
  ) {
    switch (typeStr.toLowerCase()) {
      case 'string':
        if (value is! String) {
          return ValidationResult.invalid(
            paramName,
            'Expected string, got ${value.runtimeType}',
          );
        }
        break;

      case 'integer':
        if (value is! int) {
          if (value is String) {
            try {
              int.parse(value);
              return ValidationResult.valid(paramName);
            } catch (_) {
              return ValidationResult.invalid(
                paramName,
                'Expected integer, got non-numeric string',
              );
            }
          }
          return ValidationResult.invalid(
            paramName,
            'Expected integer, got ${value.runtimeType}',
          );
        }
        break;

      case 'number':
        if (value is! num) {
          if (value is String) {
            try {
              double.parse(value);
              return ValidationResult.valid(paramName);
            } catch (_) {
              return ValidationResult.invalid(
                paramName,
                'Expected number, got non-numeric string',
              );
            }
          }
          return ValidationResult.invalid(
            paramName,
            'Expected number, got ${value.runtimeType}',
          );
        }
        break;

      case 'boolean':
        if (value is! bool) {
          if (value is String) {
            final lower = value.toLowerCase();
            if (lower == 'true' || lower == 'false') {
              return ValidationResult.valid(paramName);
            }
          }
          return ValidationResult.invalid(
            paramName,
            'Expected boolean (true/false), got ${value.runtimeType}',
          );
        }
        break;

      case 'date':
      case 'datetime':
        if (value is! String) {
          return ValidationResult.invalid(
            paramName,
            'Expected ISO 8601 date string',
          );
        }
        try {
          DateTime.parse(value);
        } catch (_) {
          return ValidationResult.invalid(
            paramName,
            'Invalid ISO 8601 date format',
          );
        }
        break;
    }

    return ValidationResult.valid(paramName);
  }
}

/// Cache entry for tool results
class ToolCacheEntry<T> {
  final T result;
  final DateTime timestamp;
  final Duration ttl;

  ToolCacheEntry({
    required this.result,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Simple in-memory cache implementation
class SimpleToolCache implements ToolExecutionContext {
  final Map<String, ToolCacheEntry<dynamic>> _cache = {};

  @override
  dynamic getFromCache(dynamic key) {
    final cacheKey = _keyToString(key);
    final entry = _cache[cacheKey];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _cache.remove(cacheKey);
      }
      return null;
    }
    return entry.result;
  }

  @override
  void setInCache(dynamic key, dynamic value, Duration ttl) {
    final cacheKey = _keyToString(key);
    _cache[cacheKey] = ToolCacheEntry(
      result: value,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }

  String _keyToString(dynamic key) {
    if (key is Map) {
      final entries = key.entries.map((e) => '${e.key}=${e.value}').toList()
        ..sort();
      return entries.join('&');
    }
    return key.toString();
  }

  @override
  void recordMetrics(ToolExecutionMetrics metrics) {
    // Basic metrics logging - can be enhanced with proper monitoring
    // ignore: avoid_print
    print(
      '[Tool Metrics] ${metrics.toolName}: ${metrics.executionTimeMs}ms, success: ${metrics.success}',
    );
  }

  @override
  void recordError(ToolExecutionMetrics metrics, StackTrace stackTrace) {
    // Basic error logging - can be enhanced with proper error reporting
    // ignore: avoid_print
    print('[Tool Error] ${metrics.toolName}: ${metrics.error}');
    // ignore: avoid_print
    print('Stack trace: $stackTrace');
  }

  /// Clean up expired cache entries
  void cleanup() {
    final expiredKeys = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final activeEntries = _cache.values.where((e) => !e.isExpired).length;
    return {
      'totalEntries': _cache.length,
      'activeEntries': activeEntries,
      'expiredEntries': _cache.length - activeEntries,
    };
  }
}

/// Execution metrics for a tool call
class ToolExecutionMetrics {
  final String toolName;
  final DateTime startTime;
  final DateTime? endTime;
  final int? executionTimeMs;
  final bool success;
  final String? error;
  final Map<String, dynamic>? arguments;

  ToolExecutionMetrics({
    required this.toolName,
    required this.startTime,
    this.endTime,
    this.executionTimeMs,
    required this.success,
    this.error,
    this.arguments,
  });

  Map<String, dynamic> toJson() {
    return {
      'toolName': toolName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'executionTimeMs': executionTimeMs,
      'success': success,
      'error': error,
      'arguments': arguments,
    };
  }
}

/// Context for tool execution (provides caching, metrics, etc.)
abstract class ToolExecutionContext {
  void recordMetrics(ToolExecutionMetrics metrics);
  void recordError(ToolExecutionMetrics metrics, StackTrace stackTrace);
  dynamic getFromCache(dynamic key);
  void setInCache(dynamic key, dynamic value, Duration ttl);
}

/// Enhanced tool executor with validation, timeout, and caching
class EnhancedToolExecutor {
  final ToolService _toolService;
  final ToolExecutionContext _context;
  final Duration? defaultTimeout;
  final Duration? defaultCacheTtl;

  EnhancedToolExecutor(
    this._toolService, {
    ToolExecutionContext? context,
    this.defaultTimeout,
    this.defaultCacheTtl,
  }) : _context = context ?? SimpleToolCache();

  /// Execute a tool with all enhancements
  Future<String> executeTool(
    String toolName,
    Map<String, dynamic> args, {
    Duration? timeout,
    Duration? cacheTtl,
  }) async {
    final stopwatch = Stopwatch()..start();
    ToolExecutionMetrics? metrics;
    String? result;

    try {
      // Get tool definition
      final tool = _toolService.tools.firstWhere(
        (t) => t.name == toolName,
        orElse: () => throw ToolException(toolName, 'Tool $toolName not found'),
      );

      // Validate parameters
      final validationResults = ToolParameterValidator.validateAll(
        tool.parameters,
        args,
      );

      if (!ToolParameterValidator.areAllValid(validationResults)) {
        final errors = ToolParameterValidator.getInvalid(
          validationResults,
        ).map((r) => r.toString()).join('; ');
        throw ToolExecutionException(
          'Parameter validation failed: $errors',
          toolName: toolName,
        );
      }

      // Check cache if enabled
      if (cacheTtl != null || defaultCacheTtl != null) {
        final ttl = cacheTtl ?? defaultCacheTtl!;
        final cacheKey = {'tool': toolName, 'args': args};
        final cached = _context.getFromCache(cacheKey);
        if (cached != null) {
          stopwatch.stop();
          metrics = ToolExecutionMetrics(
            toolName: toolName,
            startTime: DateTime.now().subtract(stopwatch.elapsed),
            endTime: DateTime.now(),
            executionTimeMs: stopwatch.elapsedMilliseconds,
            success: true,
            arguments: args,
          );
          _context.recordMetrics(metrics);
          return cached as String;
        }
      }

      // Execute with timeout if specified
      result = await _executeWithTimeout(
        () => _toolService.executeTool(toolName, args),
        timeout ?? defaultTimeout,
      );

      stopwatch.stop();

      // Cache result if caching enabled
      if (cacheTtl != null || defaultCacheTtl != null) {
        final ttl = cacheTtl ?? defaultCacheTtl!;
        final cacheKey = {'tool': toolName, 'args': args};
        _context.setInCache(cacheKey, result, ttl);
      }

      metrics = ToolExecutionMetrics(
        toolName: toolName,
        startTime: DateTime.now().subtract(stopwatch.elapsed),
        endTime: DateTime.now(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: true,
        arguments: args,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();

      metrics = ToolExecutionMetrics(
        toolName: toolName,
        startTime: DateTime.now().subtract(stopwatch.elapsed),
        endTime: DateTime.now(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        error: e.toString(),
        arguments: args,
      );

      _context.recordError(metrics, stackTrace);
      rethrow;
    } finally {
      if (metrics != null) {
        _context.recordMetrics(metrics);
      }
    }

    return result;
  }

  /// Execute with timeout
  Future<String> _executeWithTimeout(
    Future<String> Function() action,
    Duration? timeout,
  ) async {
    if (timeout == null) {
      return await action();
    }

    try {
      return await Future.any([
        action(),
        Future.delayed(timeout).then((_) {
          throw ToolExecutionException(
            'Tool execution timed out after ${timeout.inMilliseconds}ms',
            toolName: null,
          );
        }),
      ]);
    } catch (e) {
      if (e is ToolExecutionException && e.message.contains('timed out')) {
        rethrow;
      }
      rethrow;
    }
  }

  /// Get execution metrics from context
  Map<String, dynamic> getMetrics() {
    if (_context is SimpleToolCache) {
      return {'cache': (_context as SimpleToolCache).getStats()};
    }
    return {};
  }
}

/// Exception thrown during tool execution
class ToolExecutionException implements Exception {
  final String message;
  final String? toolName;

  ToolExecutionException(this.message, {this.toolName});

  @override
  String toString() => toolName != null
      ? 'ToolExecutionException[$toolName]: $message'
      : 'ToolExecutionException: $message';
}
