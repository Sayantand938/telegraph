import 'package:flutter/foundation.dart';
import 'modules/base_module.dart';
import 'modules/time_module.dart';
import 'modules/task_module.dart';
import 'modules/note_module.dart';

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

    // Register modules
    registerModule(TimeModule());
    registerModule(TaskModule());
    registerModule(NoteModule());

    _initialized = true;
    _logInit();
  }

  void _logInit() {
    if (!kDebugMode) return;
    debugPrint('📦 ModuleManager initialized');
    debugPrint('   └─ Registered modules: ${_modules.keys.join(', ')}');
  }

  /// Register a module
  void registerModule(BaseModule module) {
    _modules[module.moduleName] = module;
    module.init();
    if (kDebugMode) {
      debugPrint('   ├─ Module registered: ${module.moduleName}');
    }
  }

  /// Route parsed data to appropriate module
  void route(Map<String, dynamic> parsedData, DateTime timestamp) {
    if (!_initialized) init();

    final targetModule = parsedData['target_module'] as String?;

    if (targetModule == null) {
      _logError('❌ No target_module specified');
      return;
    }

    final module = _modules[targetModule];

    if (module == null) {
      _logError('❌ Unknown module: $targetModule');
      _logError('   💡 Available: ${_modules.keys.join(', ')}');
      return;
    }

    // ✅ Route to module (changed "Routing" → "Routed")
    _logDebug('🎯 Routed to module: $targetModule');
    module.handle(parsedData, timestamp);
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

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('📦 ModuleManager: $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      debugPrint('📦 ModuleManager ERROR: $message');
    }
  }
}