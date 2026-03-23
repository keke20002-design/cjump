import 'dart:math';
import 'package:flutter/material.dart';

class JunkBot {
  double x;
  double y; // world Y
  double _speed; // px/s, direction included
  double _time = 0;
  double _warnTimer = 1.0; // warning phase
  bool get isActive => _warnTimer <= 0;

  static const double hitRadius = 18.0;
  static const double moveSpeed = 120.0;

  JunkBot({required this.x, required this.y, required double screenWidth})
      : _speed = moveSpeed; // starts moving right

  void update(double dt, double screenWidth) {
    if (_warnTimer > 0) {
      _warnTimer -= dt;
      return;
    }
    _time += dt;
    x += _speed * dt;
    // Bounce off screen edges
    if (x > screenWidth - 20 || x < 20) {
      _speed = -_speed;
      x = x.clamp(20, screenWidth - 20);
    }
  }

  Rect get bounds => Rect.fromCenter(
        center: Offset(x, y),
        width: hitRadius * 2,
        height: hitRadius * 2,
      );

  void draw(Canvas canvas) {
    if (!isActive) {
      _drawWarning(canvas);
      return;
    }
    _drawBot(canvas);
  }

  void _drawWarning(Canvas canvas) {
    final flash =
        (sin((1.0 - _warnTimer) * 12) * 0.5 + 0.5).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: flash)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(x, y), 18, paint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white.withValues(alpha: flash),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  void _drawBot(Canvas canvas) {
    final bob = sin(_time * 4.0) * 3; // bobbing
    final cx = x;
    final cy = y + bob;

    // Body (broken satellite dish)
    final bodyPaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 22),
        const Radius.circular(5),
      ),
      bodyPaint,
    );

    // Glitch outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF80CBC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 22),
        const Radius.circular(5),
      ),
      outlinePaint,
    );

    // Solar panel arms
    final armPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - 30, cy - 4, 16, 8), armPaint);
    canvas.drawRect(Rect.fromLTWH(cx + 14, cy - 4, 16, 8), armPaint);

    // Solar panel cells
    final cellPaint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
          Rect.fromLTWH(cx - 29 + i * 5, cy - 3, 4, 6), cellPaint);
      canvas.drawRect(
          Rect.fromLTWH(cx + 15 + i * 5, cy - 3, 4, 6), cellPaint);
    }

    // Eye (flickering red LED)
    final eyeOn = (_time * 3).floor() % 3 != 0;
    final eyePaint = Paint()
      ..color = eyeOn ? const Color(0xFFFF1744) : const Color(0xFF4E0000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 5, cy - 2), 4, eyePaint);
    if (eyeOn) {
      final eyeGlow = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx - 5, cy - 2), 6, eyeGlow);
    }

    // Antenna (broken)
    final antPaint = Paint()
      ..color = const Color(0xFF80CBC4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx + 4, cy - 11), Offset(cx + 8, cy - 18), antPaint);
    canvas.drawLine(Offset(cx + 8, cy - 18), Offset(cx + 5, cy - 22), antPaint);

    // Damage sparks
    if ((_time * 6).floor() % 4 == 0) {
      final sparkPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(cx + 6, cy + 5), 4, sparkPaint);
    }
  }
}
