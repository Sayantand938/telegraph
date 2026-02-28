/// Abstract base class for all modules
abstract class BaseModule {
  final String moduleName;
  int _commandCount = 0;
  DateTime? _lastCommandAt;

  BaseModule(this.moduleName);

  /// Initialize module (called once by ModuleManager)
  void init() {}

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
}