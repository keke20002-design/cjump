import 'dart:math';
import 'package:flutter/material.dart';

class BlackHole {
  double x, y;
  double _time = 0;
  double _warnTimer = 1.0; // 1s warning before becoming active
  bool get isActive => _warnTimer <= 0;

  static const double pullStrength = 180.0;
  static const double range = 180.0;
  static const double hitRadius = 22.0;

  BlackHole({required this.x, required this.y});

  void update(double dt) {
    if (_warnTimer > 0) {
      _warnTimer -= dt;
      return;
    }
    _time += dt;
  }

  /// Returns velocity delta to apply to player (dvx, dvy).
  /// Pulls in normal gravity, repels in antigravity.
  (double, double) getPullDelta(
      double px, double py, bool isNormalGravity, double dt) {
    if (!isActive) return (0, 0);
    final dx = x - px;
    final dy = y - py;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist >= range || dist < 1) return (0, 0);
    final force = (1 - dist / range) * pullStrength;
    final nx = dx / dist;
    final ny = dy / dist;
    final sign = isNormalGravity ? 1.0 : -1.0; // repel in antigravity
    return (nx * force * sign * dt, ny * force * sign * dt);
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
    _drawBlackHole(canvas);
  }

  void _drawWarning(Canvas canvas) {
    final flashAlpha =
        (sin((1.0 - _warnTimer) * 12) * 0.5 + 0.5).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: flashAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(x, y), 18, paint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white.withValues(alpha: flashAlpha),
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  void _drawBlackHole(Canvas canvas) {
    // Outer glow
    final outerPaint = Paint()
      ..color = const Color(0xFF6A1B9A).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(x, y), range * 0.5, outerPaint);

    // Swirl rings (3 rings, rotating)
    for (int i = 0; i < 3; i++) {
      final ringRadius = 35.0 - i * 8.0;
      final ringAlpha = 0.4 + i * 0.2;
      final ringPaint = Paint()
        ..color = const Color(0xFFCE93D8).withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - i * 0.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 - i * 0.5);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(_time * (1.5 + i * 0.8));
      // Draw ellipse (squashed for perspective effect)
      canvas.scale(1.0, 0.4 + i * 0.15);
      canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
      canvas.restore();
    }

    // Core (black hole center)
    final corePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 20, corePaint);

    // Core glow rim
    final rimPaint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(x, y), 20, rimPaint);

    // Particle dots orbiting
    for (int i = 0; i < 6; i++) {
      final angle = _time * 2.5 + i * (pi * 2 / 6);
      final px2 = x + cos(angle) * 28;
      final py2 = y + sin(angle) * 28 * 0.5;
      final dotPaint = Paint()
        ..color = const Color(0xFFE040FB).withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px2, py2), 3, dotPaint);
    }
  }
}
