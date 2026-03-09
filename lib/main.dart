import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/config/app_config.dart';
import 'package:telegraph/core/config/platform_config.dart';
import 'package:telegraph/configure_dependencies.dart';
import 'package:telegraph/ui/app.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Detect platform-specific settings
  final platformConfig = _detectPlatformConfig();

  // Load application configuration
  final config = await AppConfig.load(platformConfig: platformConfig);

  // Initialize sqflite FFI loader for desktop platforms
  if (config.platform.useFfi) {
    sqfliteFfiInit();
    // Override the default database factory to use FFI on desktop
    // This enables SQLite to work properly on Windows/Linux/macOS
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize dependency injection with configuration
  await configureDependencies(config);

  runApp(const TerminalApp());
}

/// Detect platform-specific configuration
PlatformConfig _detectPlatformConfig() {
  bool useFfi = false;

  // Check if we're on a desktop platform
  useFfi = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  return PlatformConfig(
    useFfi: useFfi,
    customDbPath: null, // Will be set by path_provider if needed
    enableDebugLogging: false,
  );
}
