import 'dart:math';
import 'package:flutter/material.dart';

class ShieldItem {
  double x;
  double y;
  bool collected = false;
  double _floatTime = 0.0;

  static const double size = 24.0;
  static const double collectRange = 38.0;
  static const double shieldDuration = 5.0;

  ShieldItem({required this.x, required this.y});

  bool get isDead => collected;

  void update(double dt) {
    _floatTime += dt;
  }

  void draw(Canvas canvas) {
    if (isDead) return;

    final floatY = y + sin(_floatTime * 2.0) * 5.0;
    final pulse = sin(_floatTime * 5) * 0.5 + 0.5;

    canvas.save();
    canvas.translate(x, floatY);

    // 외부 glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15 + pulse * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, size * 1.1, glowPaint);

    // 배경 원
    final bgPaint = Paint()
      ..color = const Color(0xFF0A2740)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size / 2, bgPaint);

    // 회전 링
    canvas.save();
    canvas.rotate(_floatTime * 1.8);
    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7 + pulse * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: size / 2),
        0, pi * 1.4, false, ringPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: size / 2),
        pi * 1.6, pi * 1.4, false, ringPaint);
    canvas.restore();

    // 방패 아이콘
    final shieldPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = size * 0.28;
    final shieldPath = Path()
      ..moveTo(0, -s * 1.2)
      ..lineTo(s, -s * 0.5)
      ..lineTo(s, s * 0.4)
      ..quadraticBezierTo(s, s * 1.1, 0, s * 1.4)
      ..quadraticBezierTo(-s, s * 1.1, -s, s * 0.4)
      ..lineTo(-s, -s * 0.5)
      ..close();
    canvas.drawPath(shieldPath, shieldPaint);

    // S 텍스트
    final tp = TextPainter(
      text: const TextSpan(
        text: 'S',
        style: TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 + 1));

    canvas.restore();
  }
}
