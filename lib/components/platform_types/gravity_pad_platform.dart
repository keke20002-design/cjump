import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';
import '../../game/gravity_system.dart';

class GravityPadPlatform extends GamePlatform {
  GravitySystem? gravitySystem;
  double _pulseTimer = 0;

  GravityPadPlatform({required super.x, required super.y, this.gravitySystem})
      : super(
          width: kPlatformWidth,
          height: kPlatformHeight,
          type: PlatformType.gravityPad,
        );

  @override
  Color get baseColor => const Color(0xFFAB47BC);

  @override
  bool onPlayerBounce() {
    gravitySystem?.forceFlip();
    _pulseTimer = 0.4;
    return true;
  }

  @override
  void update(double dt) {
    if (_pulseTimer > 0) _pulseTimer -= dt;
  }

  @override
  void draw(Canvas canvas) {
    final pulse = (_pulseTimer > 0) ? 1.0 + _pulseTimer * 0.3 : 1.0;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(pulse, 1.0);
    canvas.translate(-x, -y);
    drawBase(canvas);

    // Draw gravity flip symbol (↕)
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Up arrow
    canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), arrowPaint);
    canvas.drawLine(Offset(x, y - 5), Offset(x - 4, y - 1), arrowPaint);
    canvas.drawLine(Offset(x, y - 5), Offset(x + 4, y - 1), arrowPaint);
    // Down arrow
    canvas.drawLine(Offset(x, y + 5), Offset(x - 4, y + 1), arrowPaint);
    canvas.drawLine(Offset(x, y + 5), Offset(x + 4, y + 1), arrowPaint);

    canvas.restore();
  }
}
