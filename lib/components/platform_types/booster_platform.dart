import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';

/// 부스터 플랫폼: 밟으면 강한 점프 (kJumpVelocity * 1.7)
class BoosterPlatform extends GamePlatform {
  BoosterPlatform({required super.x, required super.y})
      : super(
          width: kPlatformWidth,
          height: kPlatformHeight,
          type: PlatformType.booster,
        );

  static const double boostMultiplier = 1.7;

  @override
  Color get baseColor => const Color(0xFF26C6DA); // cyan

  @override
  bool onPlayerBounce() => true;

  @override
  void draw(Canvas canvas) {
    drawBase(canvas);

    // Arrow indicator in the center
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = x;
    final top = y - height / 2 - 6;
    final mid = y - height / 2 - 2;

    final path = Path()
      ..moveTo(cx, top)
      ..lineTo(cx - 6, mid)
      ..moveTo(cx, top)
      ..lineTo(cx + 6, mid);
    canvas.drawPath(path, arrowPaint);
  }
}
