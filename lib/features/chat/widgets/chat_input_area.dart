// lib/features/chat/widgets/chat_input_area.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_controller.dart';
import 'action_button.dart';

class ChatInputArea extends StatefulWidget {
  const ChatInputArea({super.key});

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSendButton = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.watch<ChatController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF202C33),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white70, size: 26),
              onPressed: chatController.isReady ? () {} : null,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: chatController.isReady,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                onChanged: (value) =>
                    setState(() => _showSendButton = value.trim().isNotEmpty),
                decoration: InputDecoration(
                  hintText: chatController.isReady
                      ? (chatController.initError != null
                            ? "Type (degraded mode)"
                            : "Type a message")
                      : "Loading...",
                  hintStyle: TextStyle(
                    color: chatController.isReady
                        ? Colors.white38
                        : Colors.white24,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(chatController),
              ),
            ),
            ActionButton(
              isReady: chatController.isReady,
              showSend: _showSendButton,
              onSend: () => _sendMessage(chatController),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(ChatController controller) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    controller.sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
    setState(() => _showSendButton = false);
  }
}
