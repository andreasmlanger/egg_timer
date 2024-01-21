import 'dart:math';
import 'package:flutter/material.dart';

class EggOverlay extends CustomPainter {
  Color bgColor;
  double percent;

  EggOverlay( {required this.bgColor, required this.percent} );

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final sweepAngle = 2 * pi * -percent;
    canvas.drawArc(Rect.fromCircle(radius: radius, center: center), -pi / 2,
        sweepAngle, true, paint);
  }
}
