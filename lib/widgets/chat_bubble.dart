import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[700] : Colors.grey[800],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: MarkdownBody(
          data: message.text,
          styleSheet: MarkdownStyleSheet(
            // Base text style
            p: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            // Code blocks
            code: TextStyle(
              color: Colors.amber[200],
              fontFamily: 'JetBrains Mono',
              backgroundColor: Colors.grey[900],
              fontSize: 14,
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            // Headings
            h1: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
            ),
            h2: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
            ),
            h3: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
            ),
            // Bold & Italic
            strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            em: TextStyle(color: Colors.grey[300], fontStyle: FontStyle.italic),
            // Links
            a: TextStyle(
              color: Colors.blue[300],
              decoration: TextDecoration.underline,
            ),
            // Lists
            listBullet: TextStyle(
              color: Colors.grey[400],
              fontFamily: 'JetBrains Mono',
            ),
            // Blockquote
            blockquote: TextStyle(
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.blue[400]!, width: 3),
              ),
            ),
          ),
          // Disable gesture detection on links if you don't want them clickable
          onTapLink: (text, href, title) {
            // Optional: handle link taps
            // For now, we just prevent default behavior
          },
          shrinkWrap: true,
        ),
      ),
    );
  }
}
