import 'dart:math';
import 'package:flutter/material.dart';
import 'package:telegraph/features/chat/widgets/tail_painter.dart';

class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});
  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bubbleColor = Color(0xFF202C33);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: -7,
              child: CustomPaint(
                size: const Size(10, 10),
                painter: TailPainter(color: bubbleColor, isMe: false),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double delay = index * 0.2;
                      double value = (_controller.value + delay) % 1.0;
                      double sinValue = (value * 2 * 3.14159);
                      double bounceY = -4 * (sin(sinValue) + 1) / 2;

                      return Transform.translate(
                        offset: Offset(0, bounceY),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
