import 'dart:math';
import 'package:flutter/material.dart';

class MagnetItem {
  double x;
  double y;
  bool collected = false;
  double _floatTime = 0.0;
  double _pulseTimer = 0.0;

  static const double size = 22.0;
  static const double collectRange = 36.0;
  static const double magnetDuration = 6.0;

  MagnetItem({required this.x, required this.y});

  bool get isDead => collected;

  void update(double dt) {
    _floatTime += dt;
    _pulseTimer += dt;
  }

  void draw(Canvas canvas) {
    if (isDead) return;

    final floatY = y + sin(_floatTime * 2.2) * 4.0;
    final pulse = (sin(_pulseTimer * 4) * 0.5 + 0.5); // 0..1

    canvas.save();
    canvas.translate(x, floatY);

    // 외부 glow (pulse)
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15 + pulse * 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, size * 0.9, glowPaint);

    // 배경 원
    final bgPaint = Paint()
      ..color = const Color(0xFF0D47A1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size / 2, bgPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8 + pulse * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, size / 2, borderPaint);

    // 자석 아이콘 (U자형)
    final iconPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final r = size * 0.22;
    final path = Path()
      ..moveTo(-r, -r * 0.5)
      ..lineTo(-r, r * 0.5)
      ..arcToPoint(Offset(r, r * 0.5),
          radius: Radius.circular(r), clockwise: false)
      ..lineTo(r, -r * 0.5);
    canvas.drawPath(path, iconPaint);

    // 자석 끝 빨강/파랑 극
    final leftPole = Paint()..color = const Color(0xFFEF5350);
    final rightPole = Paint()..color = const Color(0xFF42A5F5);
    canvas.drawRect(Rect.fromLTWH(-r - 2, -r * 0.5 - 3, 4, 5), leftPole);
    canvas.drawRect(Rect.fromLTWH(r - 2, -r * 0.5 - 3, 4, 5), rightPole);

    canvas.restore();
  }
}
