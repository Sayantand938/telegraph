import 'package:flutter/material.dart';
import 'screens/terminal_screen.dart';

class TerminalApp extends StatelessWidget {
  const TerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.greenAccent,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'JetBrainsMono',
      ),
      home: const TerminalScreen(),
    );
  }
}
