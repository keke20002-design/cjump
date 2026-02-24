import 'package:flutter/material.dart';

enum PlatformType { normal, moving, breaking, gravityPad, cloud, spike }

abstract class GamePlatform {
  double x; // center x
  double y; // center y
  double width;
  double height;
  PlatformType type;
  bool isDestroyed = false;

  GamePlatform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
  });

  Rect get bounds => Rect.fromCenter(
        center: Offset(x, y),
        width: width,
        height: height,
      );

  /// Called when a player bounces off this platform.
  /// Return true if the bounce should happen.
  bool onPlayerBounce();

  void update(double dt) {}

  void draw(Canvas canvas);

  Color get baseColor;

  void _drawDoodleRect(Canvas canvas, Rect rect, Color color) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 1.0) == Colors.white
          ? Colors.grey.shade400
          : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Slightly wobbly rect for doodle feel
    final path = Path()
      ..moveTo(rect.left + 2, rect.top + 1)
      ..lineTo(rect.right - 1, rect.top + 2)
      ..lineTo(rect.right + 1, rect.bottom - 1)
      ..lineTo(rect.left, rect.bottom + 1)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void drawBase(Canvas canvas) {
    _drawDoodleRect(canvas, bounds, baseColor);
  }
}
