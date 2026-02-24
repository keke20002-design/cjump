import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';
import '../../game/game_state.dart';

class CloudPlatform extends GamePlatform {
  CloudPlatform({required super.x, required super.y})
      : super(
          width: kPlatformWidth + 10,
          height: kPlatformHeight + 4,
          type: PlatformType.cloud,
        );

  @override
  Color get baseColor => const Color(0xFFECEFF1);

  @override
  bool onPlayerBounce() => true;

  bool isSolidForGravity(GravityState gravityState) =>
      gravityState == GravityState.normal;

  @override
  void draw(Canvas canvas) {
    final fillPaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw fluffy cloud shape
    void drawBubble(double dx, double dy, double r) {
      canvas.drawCircle(Offset(x + dx, y + dy), r, fillPaint);
    }

    drawBubble(-20, 0, 12);
    drawBubble(-5, -5, 14);
    drawBubble(10, -3, 12);
    drawBubble(22, 2, 10);
    drawBubble(0, 5, 10);

    // Outline
    final path = Path()
      ..addOval(Rect.fromCenter(center: Offset(x - 20, y), width: 24, height: 24))
      ..addOval(Rect.fromCenter(center: Offset(x - 5, y - 5), width: 28, height: 28))
      ..addOval(Rect.fromCenter(center: Offset(x + 10, y - 3), width: 24, height: 24))
      ..addOval(Rect.fromCenter(center: Offset(x + 22, y + 2), width: 20, height: 20));
    canvas.drawPath(path, strokePaint);
  }
}
