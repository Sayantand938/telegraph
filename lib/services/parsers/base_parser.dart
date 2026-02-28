import 'package:flutter/foundation.dart';

/// Abstract base class for all parsers
abstract class BaseParser {
  final String name;

  BaseParser(this.name);

  /// Process a message - to be implemented by subclasses
  void parse(String message, DateTime timestamp);

  /// Debug logging helper with structured output
  @protected
  void log(String message, DateTime timestamp, {String? metadata}) {
    if (!kDebugMode) return;

    debugPrint(
      '┌─[${name.toUpperCase()}]─────────────────────────────────────┐',
    );
    debugPrint('│  📥 Input:   $message');
    debugPrint('│  🕐 Time:    ${_formatTimestamp(timestamp)}');
    if (metadata != null) {
      // Wrap long metadata lines
      final lines = metadata.split('\n');
      for (final line in lines) {
        debugPrint('│  📋 Meta:    $line');
      }
    }
    debugPrint('└─────────────────────────────────────────────────┘');
  }

  /// Format timestamp for logs: HH:MM:SS.mmm
  String _formatTimestamp(DateTime ts) {
    return '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}.'
        '${ts.millisecond.toString().padLeft(3, '0')}';
  }

  /// Utility: Check if message starts with @
  bool isManualTrigger(String message) => message.trim().startsWith('@');

  /// Utility: Remove @ prefix for processing
  String stripManualTrigger(String message) => message.trim().startsWith('@')
      ? message.trim().substring(1).trim()
      : message.trim();
}
