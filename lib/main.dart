import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDl4HbWUi2E5CVS5y1699zE2OYhgeNPyY0",
      appId: "1:429119712284:web:21c0b8d562816ecc3b43d9",
      messagingSenderId: "429119712284",
      projectId: "telegraph-db",
    ),
  );

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
      ),
      home: const ChatScreen(),
    );
  }
}
