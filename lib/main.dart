import 'dart:io';
import 'package:flutter/material.dart';
// ✅ Import both: sqflite for mobile, sqflite_common_ffi for desktop
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:telegraph/core/utils.dart';
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/screens/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize FFI ONLY for desktop platforms
  // On Android/iOS, sqflite uses native implementation automatically
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ✅ Create and initialize engine BEFORE running app
  final engine = TelegraphEngine();
  try {
    await engine.initialize();
  } catch (e, stackTrace) {
    // App can still run in degraded mode
    debugPrint('⚠️ Engine initialization failed: $e');
    debugPrint('Stack: $stackTrace');
  }

  runApp(TelegraphApp(engine: engine));
}

class TelegraphApp extends StatelessWidget {
  final TelegraphEngine engine;

  const TelegraphApp({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegraph',
      debugShowCheckedModeBanner: false,
      scrollBehavior: NoScrollbarBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'JetBrainsMono',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A884),
          brightness: Brightness.dark,
          surface: const Color(0xFF0B141A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF202C33),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white70),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF00A884),
          selectionColor: Color(0xFF00A884),
          selectionHandleColor: Color(0xFF00A884),
        ),
      ),
      home: ChatScreen(engine: engine), // ✅ Inject engine here
    );
  }
}
