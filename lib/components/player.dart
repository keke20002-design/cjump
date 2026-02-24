import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../game/gravity_system.dart';

class PlayerComponent {
  // World position (center of character)
  double x;
  double y;
  double velocityX = 0;
  double velocityY = 0;

  bool isDead = false;

  // For doodle-style animation
  double _blinkTimer = 0;
  bool _eyeOpen = true;
  double _squishFactor = 1.0; // 1=normal, <1=squished on bounce
  double _squishTimer = 0;

  PlayerComponent({required this.x, required this.y});

  double get width => kCharacterSize;
  double get height => kCharacterSize;

  Rect get bounds => Rect.fromCenter(
        center: Offset(x, y),
        width: width * 0.85, // slightly smaller hitbox than visual
        height: height * 0.85,
      );

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    velocityX = 0;
    velocityY = -kJumpVelocity; // start with upward momentum
    isDead = false;
    _squishFactor = 1.0;
  }

  void update(double dt, GravitySystem gravity, double screenWidth) {
    // Apply gravity
    velocityY += gravity.effectiveGravity * dt;

    // Update position
    x += velocityX * dt;
    y += velocityY * dt;

    // Horizontal screen wrap
    if (x < -width / 2) x = screenWidth + width / 2;
    if (x > screenWidth + width / 2) x = -width / 2;

    // Squish animation on bounce
    if (_squishTimer > 0) {
      _squishTimer -= dt;
      _squishFactor = 1.0 + 0.3 * (_squishTimer / 0.15).clamp(0, 1);
    } else {
      _squishFactor = 1.0;
    }

    // Blink animation
    _blinkTimer += dt;
    if (_blinkTimer > 3.0) {
      _eyeOpen = false;
      if (_blinkTimer > 3.15) {
        _eyeOpen = true;
        _blinkTimer = 0;
      }
    }
  }

  void onBounce() {
    _squishTimer = 0.15;
  }

  void draw(Canvas canvas, bool isNormalGravity) {
    canvas.save();
    canvas.translate(x, y);

    // Flip upside-down in antigravity mode
    if (!isNormalGravity) {
      canvas.scale(1, -1);
    }

    // Squish: wider and shorter on bounce
    canvas.scale(1.0 / _squishFactor, _squishFactor);

    final halfW = width / 2;
    final halfH = height / 2;

    // Body - doodle creature oval
    final bodyPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: width * 0.9,
      height: height * 0.85,
    );
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // Eyes
    _drawEyes(canvas, halfW, halfH);

    // Feet / legs
    _drawLegs(canvas, halfW, halfH);

    canvas.restore();
  }

  void _drawEyes(Canvas canvas, double halfW, double halfH) {
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const eyeY = -4.0;
    const eyeRadius = 6.0;
    const eyeSpacing = 9.0;

    for (final signX in [-1.0, 1.0]) {
      final eyeCenter = Offset(signX * eyeSpacing, eyeY);
      canvas.drawCircle(eyeCenter, eyeRadius, eyePaint);
      canvas.drawCircle(eyeCenter, eyeRadius, outlinePaint);
      if (_eyeOpen) {
        canvas.drawCircle(eyeCenter + const Offset(1, 1), 3.5, pupilPaint);
      } else {
        // Closed eye = line
        final linePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          eyeCenter - const Offset(eyeRadius * 0.7, 0),
          eyeCenter + const Offset(eyeRadius * 0.7, 0),
          linePaint,
        );
      }
    }
  }

  void _drawLegs(Canvas canvas, double halfW, double halfH) {
    final legPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-halfW * 0.4, halfH * 0.7),
      Offset(-halfW * 0.6, halfH),
      legPaint,
    );
    canvas.drawLine(
      Offset(halfW * 0.4, halfH * 0.7),
      Offset(halfW * 0.6, halfH),
      legPaint,
    );
  }
}
