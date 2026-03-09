import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/configure_dependencies.dart';
import 'package:telegraph/ui/app.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI loader for desktop platforms
  sqfliteFfiInit();

  // ⭐ CRITICAL: Override the default database factory to use FFI on desktop
  // This enables SQLite to work properly on Windows/Linux/macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize dependency injection (async)
  await configureDependencies();

  runApp(const TerminalApp());
}
