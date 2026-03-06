// lib/features/chat/widgets/action_button.dart
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final bool isReady;
  final bool showSend;
  final VoidCallback onSend;

  const ActionButton({
    super.key,
    required this.isReady,
    required this.showSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey,
          child: Icon(Icons.hourglass_empty, color: Colors.white, size: 18),
        ),
      );
    }

    if (showSend) {
      return GestureDetector(
        onTap: onSend,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF00A884),
            child: Icon(Icons.send, color: Colors.black, size: 18),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.mic, color: Colors.white70, size: 24),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Voice input coming soon!'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
