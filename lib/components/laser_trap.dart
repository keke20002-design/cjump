import 'dart:math';
import 'package:flutter/material.dart';

enum LaserState { off, warning, on }

class LaserTrap {
  final double x; // left edge in world space
  double y; // world Y center
  final double width;

  static const double hitHalfHeight = 8.0;
  static const double _offDuration = 1.5;
  static const double _warnDuration = 0.5;
  static const double _onDuration = 0.8;

  LaserState state = LaserState.off;
  double _timer = 0;

  LaserTrap({required this.x, required this.y, required this.width}) {
    // Start at a random phase so lasers don't all pulse in sync
    _timer = Random().nextDouble() * (_offDuration + _warnDuration + _onDuration);
    _updateState();
  }

  bool get isActive => state == LaserState.on;

  Rect get bounds => Rect.fromCenter(
        center: Offset(x + width / 2, y),
        width: width,
        height: hitHalfHeight * 2,
      );

  void _updateState() {
    final cycle = _offDuration + _warnDuration + _onDuration;
    final t = _timer % cycle;
    if (t < _offDuration) {
      state = LaserState.off;
    } else if (t < _offDuration + _warnDuration) {
      state = LaserState.warning;
    } else {
      state = LaserState.on;
    }
  }

  void update(double dt) {
    _timer += dt;
    _updateState();
  }

  void draw(Canvas canvas) {
    if (state == LaserState.off) return;

    final isOn = state == LaserState.on;
    // Warning: flicker by oscillating alpha
    final flickerAlpha = isOn
        ? 1.0
        : ((sin(_timer * 25) * 0.5 + 0.5) * 0.8 + 0.2).clamp(0.0, 1.0);

    final color = isOn ? const Color(0xFFFF1744) : const Color(0xFFFF6D00);
    final cx = x + width / 2;

    // Outer glow
    canvas.drawLine(
      Offset(x, y),
      Offset(x + width, y),
      Paint()
        ..color = color.withValues(alpha: flickerAlpha * 0.25)
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Mid glow
    canvas.drawLine(
      Offset(x, y),
      Offset(x + width, y),
      Paint()
        ..color = color.withValues(alpha: flickerAlpha * 0.55)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Core beam
    canvas.drawLine(
      Offset(x, y),
      Offset(x + width, y),
      Paint()
        ..color = Colors.white.withValues(alpha: flickerAlpha * 0.9)
        ..strokeWidth = isOn ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Emitter nodes at each end
    final nodePaint = Paint()
      ..color = color.withValues(alpha: flickerAlpha)
      ..style = PaintingStyle.fill;
    final nodeGlow = Paint()
      ..color = color.withValues(alpha: flickerAlpha * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final nx in [x, x + width]) {
      canvas.drawCircle(Offset(nx, y), 7, nodeGlow);
      canvas.drawCircle(Offset(nx, y), 4, nodePaint);
    }

    // Warning label (centre, only in warning state)
    if (!isOn) {
      final tp = TextPainter(
        text: TextSpan(
          text: '!',
          style: TextStyle(
            color: const Color(0xFFFF6D00).withValues(alpha: flickerAlpha),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height - 6));
    }
  }
}
