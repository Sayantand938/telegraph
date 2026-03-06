// lib/features/chat/widgets/message_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_controller.dart';
import 'chat_bubble.dart';
import 'typing_bubble.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();

    // Auto-scroll when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: controller.messages.length + (controller.isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.messages.length) return const TypingBubble();
          return ChatBubble(message: controller.messages[index]);
        },
      ),
    );
  }

  void _scrollToBottom() {
    if (mounted && _scrollController.hasClients) {
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        // Silently fail scroll
      }
    }
  }
}
