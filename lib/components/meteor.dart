import 'dart:math';
import 'package:flutter/material.dart';

class Meteor {
  double x;
  double y;
  final double speed;
  final double radius;
  final double _angle;
  double _time = 0;
  bool active = true;

  // hitRadius scales with visual radius
  double get hitRadius => radius * 0.75;

  Meteor({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required double angle,
  }) : _angle = angle;

  void update(double dt) {
    y += speed * dt;
    x += sin(_angle) * speed * 0.3 * dt;
    _time += dt;
  }

  Rect get bounds => Rect.fromCenter(
        center: Offset(x, y),
        width: hitRadius * 2,
        height: hitRadius * 2,
      );

  void draw(Canvas canvas) {
    canvas.save();
    canvas.translate(x, y);

    final pulse = sin(_time * 8.0); // 빠른 박동

    // ── 1. 원거리 대기권 진입 열기 (atmospheric entry glow) ──
    final atmosPaint = Paint()
      ..color = const Color(0xFFFF3D00).withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 2.2);
    canvas.drawCircle(Offset(0, -radius * 0.5), radius * 3.0, atmosPaint);

    // ── 2. 화염 꼬리 (메인 — 위쪽으로 긴 불꽃 스트림) ──
    _drawFlameTail(canvas, pulse);

    // ── 3. 외부 화염 링 ──
    final fireRingPaint = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.55 + pulse * 0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.9);
    canvas.drawCircle(Offset.zero, radius * 1.35, fireRingPaint);

    // ── 4. 운석 몸체 ──
    canvas.rotate(_time * 1.2); // 회전

    final basePaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, radius, basePaint);

    // 몸체 밝은 면
    final litPaint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(-radius * 0.2, -radius * 0.2), radius * 0.65, litPaint);

    // 몸체 테두리 (불에 달궈진 붉은 림)
    final rimPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.22
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15);
    canvas.drawCircle(Offset.zero, radius * 0.95, rimPaint);

    // 크레이터
    _drawCraters(canvas, radius);

    // ── 5. 핫스팟 (중심 밝은 불꽃) ──
    final hotPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45 + pulse * 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);
    canvas.drawCircle(Offset(-radius * 0.15, -radius * 0.15),
        radius * 0.45, hotPaint);

    canvas.restore();
  }

  void _drawFlameTail(Canvas canvas, double pulse) {
    final tailLen = radius * 4.5 + pulse * radius * 0.4;

    // 외부 불꽃 (붉은)
    final outerFlame = Paint()
      ..color = const Color(0xFFD32F2F).withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8);
    final outerPath = Path()
      ..moveTo(-radius * 0.7, -radius * 0.3)
      ..quadraticBezierTo(-radius * 1.1, -tailLen * 0.5,
          -radius * 0.1 + pulse * 3, -tailLen)
      ..quadraticBezierTo(
          radius * 1.1, -tailLen * 0.5, radius * 0.7, -radius * 0.3)
      ..close();
    canvas.drawPath(outerPath, outerFlame);

    // 중간 불꽃 (주황)
    final midFlame = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);
    final midPath = Path()
      ..moveTo(-radius * 0.5, -radius * 0.2)
      ..quadraticBezierTo(-radius * 0.7, -tailLen * 0.55,
          pulse * 2, -tailLen * 0.88)
      ..quadraticBezierTo(
          radius * 0.7, -tailLen * 0.55, radius * 0.5, -radius * 0.2)
      ..close();
    canvas.drawPath(midPath, midFlame);

    // 내부 불꽃 (노란 — 가장 밝음)
    final innerFlame = Paint()
      ..color = const Color(0xFFFFCA28).withValues(alpha: 0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.25);
    final innerPath = Path()
      ..moveTo(-radius * 0.28, -radius * 0.1)
      ..quadraticBezierTo(-radius * 0.35, -tailLen * 0.45,
          pulse * 1.5, -tailLen * 0.6)
      ..quadraticBezierTo(
          radius * 0.35, -tailLen * 0.45, radius * 0.28, -radius * 0.1)
      ..close();
    canvas.drawPath(innerPath, innerFlame);
  }

  void _drawCraters(Canvas canvas, double r) {
    final craterPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(r * 0.25, r * 0.2), r * 0.22, craterPaint);
    canvas.drawCircle(Offset(-r * 0.3, r * 0.35), r * 0.14, craterPaint);
    canvas.drawCircle(Offset(r * 0.05, -r * 0.3), r * 0.1, craterPaint);
  }
}
