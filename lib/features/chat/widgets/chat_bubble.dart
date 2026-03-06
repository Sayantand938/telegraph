import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:telegraph/features/chat/models/message_model.dart';
import 'package:markdown/markdown.dart' as md;
import 'tail_painter.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isMe
        ? const Color(0xFF005C4B)
        : const Color(0xFF202C33);

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontFamily: 'JetBrainsMono',
    );

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              right: message.isMe ? -7 : null,
              left: message.isMe ? null : -7,
              child: CustomPaint(
                size: const Size(10, 10),
                painter: TailPainter(color: bubbleColor, isMe: message.isMe),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.92,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isMe ? 12 : 0),
                  topRight: Radius.circular(message.isMe ? 0 : 12),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: const Radius.circular(12),
                ),
              ),
              child: MarkdownBody(
                data: message.text,
                builders: {'code': JsonSyntaxBuilder()},
                styleSheet: MarkdownStyleSheet(
                  p: textStyle,
                  strong: textStyle.copyWith(fontWeight: FontWeight.bold),
                  code: textStyle.copyWith(
                    backgroundColor: Colors.transparent,
                    fontSize: 15,
                  ),
                  codeblockPadding: EdgeInsets.zero,
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // ✅ onError callback removed - not supported by flutter_markdown_plus
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JsonSyntaxBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    try {
      final text = element.textContent;
      if (!text.trim().startsWith('{') && !text.trim().startsWith('[')) {
        return null;
      }
      return _JsonCodeBlock(text: text);
    } catch (e) {
      debugPrint('⚠️ JsonSyntaxBuilder error: $e');
      return null;
    }
  }
}

class _JsonCodeBlock extends StatefulWidget {
  final String text;

  const _JsonCodeBlock({required this.text});

  @override
  State<_JsonCodeBlock> createState() => _JsonCodeBlockState();
}

class _JsonCodeBlockState extends State<_JsonCodeBlock> {
  bool _copied = false;

  void _copyToClipboard() {
    try {
      Clipboard.setData(ClipboardData(text: widget.text)).then((_) {
        if (mounted) {
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _copied = false);
          });
        }
      });
    } catch (e) {
      debugPrint('⚠️ Clipboard copy error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to copy to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 44, 12),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 15,
                height: 1.4,
              ),
              children: _highlightJson(widget.text),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            onPressed: _copyToClipboard,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _copied ? Icons.check : Icons.copy_all_outlined,
              size: 20,
              color: _copied ? const Color(0xFF00A884) : Colors.white38,
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _highlightJson(String json) {
    try {
      final List<TextSpan> spans = [];
      final regExp = RegExp(
        r'("(?:\\.|[^"])*")(?=\s*:)|("(?:\\.|[^"])*")|(\b\d+(?:\.\d+)?\b|\btrue\b|\bfalse\b|\bnull\b)|([\{\}\[\]\:,])',
        dotAll: true,
      );

      int lastMatchEnd = 0;

      for (final match in regExp.allMatches(json)) {
        if (match.start > lastMatchEnd) {
          spans.add(
            TextSpan(
              text: json.substring(lastMatchEnd, match.start),
              style: const TextStyle(color: Colors.white38),
            ),
          );
        }

        if (match.group(1) != null) {
          spans.add(
            TextSpan(
              text: match.group(1),
              style: const TextStyle(color: Color(0xFF9CDCFE)),
            ),
          );
        } else if (match.group(2) != null) {
          spans.add(
            TextSpan(
              text: match.group(2),
              style: const TextStyle(color: Color(0xFFCE9178)),
            ),
          );
        } else if (match.group(3) != null) {
          spans.add(
            TextSpan(
              text: match.group(3),
              style: const TextStyle(color: Color(0xFFB5CEA8)),
            ),
          );
        } else if (match.group(4) != null) {
          spans.add(
            TextSpan(
              text: match.group(4),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        lastMatchEnd = match.end;
      }

      if (lastMatchEnd < json.length) {
        spans.add(
          TextSpan(
            text: json.substring(lastMatchEnd),
            style: const TextStyle(color: Colors.white38),
          ),
        );
      }

      return spans;
    } catch (e) {
      debugPrint('⚠️ JSON highlight error: $e');
      // Fallback: return plain text
      return [
        TextSpan(
          text: json,
          style: const TextStyle(color: Colors.white),
        ),
      ];
    }
  }
}
