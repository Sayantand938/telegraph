// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
// ✅ Add this import for DatabaseHelper
import 'services/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize SQLite FFI for Windows/desktop support
  // (Safe to call on all platforms - only does something on desktop)
  DatabaseHelper.init();

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Echo Chat',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
