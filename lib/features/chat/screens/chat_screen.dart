// lib/features/chat/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Or your preferred state management
import 'package:telegraph/core/engine/telegraph_engine.dart';
import 'package:telegraph/features/chat/controllers/chat_controller.dart';
import 'package:telegraph/features/chat/widgets/chat_app_bar.dart';
import 'package:telegraph/features/chat/widgets/message_list.dart';
import 'package:telegraph/features/chat/widgets/chat_input_area.dart';

class ChatScreen extends StatefulWidget {
  final TelegraphEngine engine;
  const ChatScreen({super.key, required this.engine});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController(engine: widget.engine);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatController>.value(
      value: _controller,
      child: Scaffold(
        appBar: const ChatAppBar(),
        body: Container(
          color: const Color(0xFF0B141A),
          child: Stack(
            children: [
              _buildBackground(),
              const Column(children: [MessageList(), ChatInputArea()]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.06,
        child: Image.asset(
          'assets/images/chat_bg.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(),
        ),
      ),
    );
  }
}
