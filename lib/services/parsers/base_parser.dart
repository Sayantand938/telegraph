/// Abstract base class for all parsers
abstract class BaseParser {
  final String name;

  BaseParser(this.name);

  /// Process a message and return formatted response for UI
  Future<String> parse(String message, DateTime timestamp);

  /// Utility: Check if message starts with @
  bool isManualTrigger(String message) => message.trim().startsWith('@');

  /// Utility: Remove @ prefix for processing
  String stripManualTrigger(String message) => message.trim().startsWith('@')
      ? message.trim().substring(1).trim()
      : message.trim();
}