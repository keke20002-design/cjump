
import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';

class MovingPlatform extends GamePlatform {
  final double _speed;
  final double _leftBound;
  final double _rightBound;
  double _direction = 1.0;

  MovingPlatform({
    required super.x,
    required super.y,
    required double screenWidth,
    double speed = 80.0,
  })  : _speed = speed,
        _leftBound = kPlatformWidth / 2,
        _rightBound = screenWidth - kPlatformWidth / 2,
        super(
          width: kPlatformWidth,
          height: kPlatformHeight,
          type: PlatformType.moving,
        );

  @override
  Color get baseColor => const Color(0xFF42A5F5);

  @override
  bool onPlayerBounce() => true;

  @override
  void update(double dt) {
    x += _direction * _speed * dt;
    if (x > _rightBound) {
      x = _rightBound;
      _direction = -1;
    } else if (x < _leftBound) {
      x = _leftBound;
      _direction = 1;
    }
  }

  @override
  void draw(Canvas canvas) {
    drawBase(canvas);
    // Draw motion arrows
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final mid = Offset(x, y);
    canvas.drawLine(
        mid - const Offset(10, 0), mid + const Offset(10, 0), arrowPaint);
    final arrowDir = _direction;
    canvas.drawLine(mid + Offset(10 * arrowDir, 0),
        mid + Offset(6 * arrowDir, -3), arrowPaint);
    canvas.drawLine(mid + Offset(10 * arrowDir, 0),
        mid + Offset(6 * arrowDir, 3), arrowPaint);
  }
}
