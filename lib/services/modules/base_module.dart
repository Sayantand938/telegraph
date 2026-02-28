// No flutter/foundation import needed for basic logging
// Using dart:developer for debugPrint instead

import 'dart:developer' as developer;

/// Abstract base class for all modules
abstract class BaseModule {
  final String moduleName;
  int _commandCount = 0;
  DateTime? _lastCommandAt;

  BaseModule(this.moduleName);

  /// Initialize module (called once by ModuleManager)
  void init() {
    _logInit();
  }

  /// Handle parsed command - to be implemented by subclasses
  void handle(Map<String, dynamic> data, DateTime timestamp);

  /// Get module statistics
  Map<String, dynamic> getStats() {
    return {
      'name': moduleName,
      'commandCount': _commandCount,
      'lastCommandAt': _lastCommandAt?.toIso8601String() ?? 'N/A',
    };
  }

  /// Reset statistics
  void resetStats() {
    _commandCount = 0;
    _lastCommandAt = null;
  }

  /// Increment command counter (public for subclasses)
  void incrementCommand() {
    _commandCount++;
    _lastCommandAt = DateTime.now();
  }

  /// Debug logger (public for subclasses)
  void log(String message, {String level = 'INFO'}) {
    final emoji = _getLevelEmoji(level);
    developer.log('[$moduleName] $emoji $message', name: 'ModuleLogger');
  }

  String _getLevelEmoji(String level) {
    switch (level) {
      case 'INFO':
        return 'ℹ️';
      case 'SUCCESS':
        return '✅';
      case 'WARNING':
        return '⚠️';
      case 'ERROR':
        return '❌';
      default:
        return '📝';
    }
  }

  void _logInit() {
    developer.log(
      '   └─ [$moduleName] Module initialized',
      name: 'ModuleLogger',
    );
  }
}
