import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';

class BreakingPlatform extends GamePlatform {
  bool _isBroken = false;
  double _breakTimer = 0;
  static const _breakDelay = 0.1;
  static const _fadeTime = 0.3;

  BreakingPlatform({required super.x, required super.y})
      : super(
          width: kPlatformWidth,
          height: kPlatformHeight,
          type: PlatformType.breaking,
        );

  @override
  Color get baseColor => const Color(0xFFFFA726);

  @override
  bool onPlayerBounce() {
    if (_isBroken) return false;
    _isBroken = true;
    return true; // allow one bounce, then destroy
  }

  @override
  void update(double dt) {
    if (_isBroken) {
      _breakTimer += dt;
      if (_breakTimer > _breakDelay + _fadeTime) {
        isDestroyed = true;
      }
    }
  }

  @override
  void draw(Canvas canvas) {
    if (!_isBroken) {
      drawBase(canvas);
      // Crack lines
      final crackPaint = Paint()
        ..color = Colors.brown.shade700
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x - 15, y - 2),
        Offset(x - 5, y + 3),
        crackPaint,
      );
      canvas.drawLine(
        Offset(x + 5, y - 3),
        Offset(x + 15, y + 2),
        crackPaint,
      );
    } else {
      // Shatter pieces
      final alpha = (1.0 - (_breakTimer - _breakDelay) / _fadeTime).clamp(0.0, 1.0);
      final piecePaint = Paint()
        ..color = baseColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      final offset = _breakTimer * 80;
      for (final dx in [-20.0, 0.0, 20.0]) {
        final rect = Rect.fromCenter(
          center: Offset(x + dx, y + offset),
          width: 20,
          height: kPlatformHeight,
        );
        canvas.drawRect(rect, piecePaint);
      }
    }
  }
}
