import 'package:flutter/material.dart';

class TailPainter extends CustomPainter {
  final Color color;
  final bool isMe;
  TailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(10, 0);
      path.lineTo(0, 12);
    } else {
      path.moveTo(10, 0);
      path.lineTo(0, 0);
      path.lineTo(10, 12);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
