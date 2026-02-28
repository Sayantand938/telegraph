// lib/services/module_manager.dart
import 'modules/base_module.dart';
// ✅ Updated import path for refactored TimeModule
import 'modules/time_module/time_module.dart';
import 'modules/task_module.dart';
import 'modules/note_module.dart';
import 'modules/chat_module.dart';

class ModuleManager {
  static final ModuleManager _instance = ModuleManager._internal();
  factory ModuleManager() => _instance;
  ModuleManager._internal();

  final Map<String, BaseModule> _modules = {};
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    registerModule(TimeModule());
    registerModule(TaskModule());
    registerModule(NoteModule());
    registerModule(ChatModule());
    _initialized = true;
  }

  void registerModule(BaseModule module) {
    _modules[module.moduleName] = module;
    module.init();
  }

  // ✅ CHANGE 1: Make route async
  Future<String?> route(
    Map<String, dynamic> parsedData,
    DateTime timestamp,
  ) async {
    if (!_initialized) init();
    final targetModule = parsedData['target_module'] as String? ?? 'chat';
    final module = _modules[targetModule];
    if (module == null) {
      return '❌ Module "$targetModule" not found. Available: ${_modules.keys.join(", ")}';
    }
    // ✅ CHANGE 2: Await the async handle method
    return await module.handle(parsedData, timestamp);
  }

  List<String> getAvailableModules() => _modules.keys.toList();

  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};
    for (final entry in _modules.entries) {
      stats[entry.key] = entry.value.getStats();
    }
    return stats;
  }

  void resetStats() {
    for (final module in _modules.values) {
      module.resetStats();
    }
  }
}
