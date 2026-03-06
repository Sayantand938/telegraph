// lib/core/module_interface.dart
abstract class FeatureCommandHandler {
  /// ✅ Unique identifier for this module (e.g., 'time', 'finance')
  String get moduleKey;
  bool canHandle(String input);
  Future<String> handle(String input);
  String get helpText;
}

abstract class TelegraphModule {
  /// Human-readable name for the module
  String get name;

  /// The command handler for this module
  FeatureCommandHandler get handler;

  /// SQL scripts to create tables for this module
  List<String> get onCreateSql;

  /// ✅ Optional: Enable/disable flag for feature toggles
  bool get isEnabled => true;

  /// ✅ Optional: Module version for migrations
  int get version => 1;
}
