import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'ui/app.dart';

void main() async {
  // Ensure Flutter bindings are initialized before using async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI loader for desktop platforms
  sqfliteFfiInit();

  // ⭐ CRITICAL: Override the default database factory to use FFI on desktop
  // This enables SQLite to work properly on Windows/Linux/macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const TerminalApp());
}
