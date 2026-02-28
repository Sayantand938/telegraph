import 'modules/base_module.dart';
import 'modules/time_module.dart';
import 'modules/task_module.dart';
import 'modules/note_module.dart';
import 'modules/chat_module.dart';

/// Routes parsed commands to appropriate module managers
class ModuleManager {
  // Singleton
  static final ModuleManager _instance = ModuleManager._internal();
  factory ModuleManager() => _instance;
  ModuleManager._internal();

  // Module registry
  final Map<String, BaseModule> _modules = {};
  bool _initialized = false;

  /// Initialize all modules
  void init() {
    if (_initialized) return;

    registerModule(TimeModule());
    registerModule(TaskModule());
    registerModule(NoteModule());
    registerModule(ChatModule()); // For general AI conversations

    _initialized = true;
  }

  /// Register a module
  void registerModule(BaseModule module) {
    _modules[module.moduleName] = module;
    module.init();
  }

  /// Route parsed data to module and return user-facing response
  String? route(Map<String, dynamic> parsedData, DateTime timestamp) {
    if (!_initialized) init();

    final targetModule = parsedData['target_module'] as String?;
    if (targetModule == null) return '❌ No target_module specified';

    final module = _modules[targetModule];
    if (module == null) {
      return '❌ Module "$targetModule" not found. Available: ${_modules.keys.join(", ")}';
    }

    // Route to module handler
    return module.handle(parsedData, timestamp);
  }

  /// Get list of available modules
  List<String> getAvailableModules() {
    return _modules.keys.toList();
  }

  /// Get module stats
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};
    for (final entry in _modules.entries) {
      stats[entry.key] = entry.value.getStats();
    }
    return stats;
  }

  /// Reset all module stats
  void resetStats() {
    for (final module in _modules.values) {
      module.resetStats();
    }
  }
}
