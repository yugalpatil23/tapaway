import 'dart:math';

import 'package:flutter/material.dart';

class StarPainter extends CustomPainter {
  final bool filled;
  const StarPainter({required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.42;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      // Start at top point, rotate each step by 36°
      final angle = (i * 3.14159265358979 / 5) - 3.14159265358979 / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = filled ? const Color(0xFFFFD60A) : const Color(0xFF252538)
        ..style = PaintingStyle.fill,
    );
  }

  // Only repaint when filled state changes — never during scroll
  @override
  bool shouldRepaint(StarPainter old) => old.filled != filled;
}
