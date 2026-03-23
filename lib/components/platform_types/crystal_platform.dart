import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';

class CrystalPlatform extends GamePlatform {
  bool _isStepped = false;
  double _breakTimer = 0;
  static const _breakDelay = 0.5; // 0.5s before shattering
  static const _fadeTime = 0.35;

  CrystalPlatform({required super.x, required super.y})
      : super(
            width: kPlatformWidth,
            height: kPlatformHeight,
            type: PlatformType.crystal);

  @override
  Color get baseColor => const Color(0xFFFF4081);

  @override
  bool onPlayerBounce() {
    if (_isStepped) return false;
    _isStepped = true;
    return true; // bounce once, then shatter after delay
  }

  @override
  void update(double dt) {
    if (_isStepped) {
      _breakTimer += dt;
      if (_breakTimer > _breakDelay + _fadeTime) isDestroyed = true;
    }
  }

  @override
  void draw(Canvas canvas) {
    if (!_isStepped) {
      _drawCrystal(canvas);
    } else if (_breakTimer < _breakDelay) {
      // Cracking phase: draw with cracks
      _drawCracking(canvas);
    } else {
      // Shatter phase
      _drawShatter(canvas);
    }
  }

  void _drawCrystal(Canvas canvas) {
    // Neon pink crystal glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.inflate(3), const Radius.circular(4)),
      glowPaint,
    );

    // Crystal body
    final bodyPaint = Paint()
      ..color = const Color(0xFFFF80AB)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(3)),
      bodyPaint,
    );

    // Shimmer highlight
    final shimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final shimRect = Rect.fromLTWH(
        bounds.left + 4, bounds.top + 2, bounds.width * 0.3, bounds.height * 0.5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(shimRect, const Radius.circular(2)), shimPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFF50057)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(3)),
      borderPaint,
    );
  }

  void _drawCracking(Canvas canvas) {
    _drawCrystal(canvas);
    // Crack lines
    final crackPaint = Paint()
      ..color = const Color(0xFFF50057).withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x - 12, y - 2), Offset(x, y + 3), crackPaint);
    canvas.drawLine(Offset(x, y + 3), Offset(x + 10, y - 4), crackPaint);
    canvas.drawLine(Offset(x - 5, y - 3), Offset(x - 18, y + 4), crackPaint);
    canvas.drawLine(Offset(x + 5, y - 2), Offset(x + 16, y + 5), crackPaint);
  }

  void _drawShatter(Canvas canvas) {
    final t = (_breakTimer - _breakDelay) / _fadeTime;
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    final spread = t * 40;
    final piecePaint = Paint()
      ..color = const Color(0xFFFF80AB).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: alpha * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final offsets = [
      Offset(-spread * 0.7, -spread * 0.5),
      Offset(spread * 0.6, -spread * 0.4),
      Offset(-spread * 0.3, spread * 0.6),
      Offset(spread * 0.8, spread * 0.3),
      Offset(0, -spread),
    ];
    for (final off in offsets) {
      final r = Rect.fromCenter(
          center: Offset(x + off.dx, y + off.dy), width: 10, height: 8);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2)), glowPaint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2)), piecePaint);
    }
  }
}
