import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FlashlightPainter extends CustomPainter {
  final double opacity;
  final Color color;
  final double length;
  final double width;

  FlashlightPainter({
    required this.opacity,
    required this.color,
    required this.length,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity * 0.9),
          color.withOpacity(opacity * 0.6),
          color.withOpacity(opacity * 0.3),
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
        center: const Alignment(0.0, 0.5),
        focal: const Alignment(0.0, 0.3),
        focalRadius: 0.3,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = ui.Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width / 2 - width, -length)
      ..lineTo(size.width / 2 + width, -length)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FlashlightPainter oldDelegate) =>
      opacity != oldDelegate.opacity ||
      length != oldDelegate.length ||
      width != oldDelegate.width;
}
