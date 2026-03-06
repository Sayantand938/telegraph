// lib/core/module_registry.dart
import 'package:telegraph/core/module_interface.dart';

/// Centralized registry for all Telegraph modules.
/// Enables dynamic module registration, feature flags, and easier testing.
class ModuleRegistry {
  final Map<String, TelegraphModule> _modules = {};

  /// Register a module with its unique key
  void register(TelegraphModule module) {
    final key = module.handler.moduleKey;
    if (key.isEmpty) {
      throw ArgumentError('Module must have a non-empty moduleKey');
    }
    _modules[key] = module;
  }

  /// Register multiple modules at once
  void registerAll(List<TelegraphModule> modules) {
    for (final module in modules) {
      register(module);
    }
  }

  /// Get a module by its key
  TelegraphModule? getModule(String key) => _modules[key];

  /// Get all registered modules
  List<TelegraphModule> get allModules => _modules.values.toList();

  /// Get all command handlers
  List<FeatureCommandHandler> get allHandlers =>
      _modules.values.map((m) => m.handler).toList();

  /// Get all SQL creation scripts from registered modules
  List<String> get allCreateSql =>
      _modules.values.expand((m) => m.onCreateSql).toList();

  /// Check if a module is registered
  bool isRegistered(String key) => _modules.containsKey(key);

  /// Unregister a module (useful for feature flags)
  void unregister(String key) {
    _modules.remove(key);
  }

  /// Clear all modules (useful for testing)
  void clear() {
    _modules.clear();
  }

  /// Get module count
  int get count => _modules.length;
}
