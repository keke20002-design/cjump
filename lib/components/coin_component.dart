import 'dart:math';
import 'package:flutter/material.dart';

enum CoinState { idle, collected }

/// 인게임에서 플랫폼 위에 스폰되어 플레이어가 수집하는 코인 아이템
class CoinComponent {
  double x;
  double y;
  double vy; // 코인 비 낙하 속도 (기본 0)
  CoinState state = CoinState.idle;
  double _rotAngle = 0.0;
  double _floatOffset = 0.0;
  double _floatTime = 0.0;
  double _collectAnim = 0.0;

  final bool isBigCoin; // 큰 코인 = 5배 가치

  static const double size = 18.0;
  static const double bigSize = 26.0;
  static const double magnetRange = 60.0;

  CoinComponent({required this.x, required this.y, this.isBigCoin = false, this.vy = 0});

  int get value => isBigCoin ? 5 : 1;
  double get _radius => (isBigCoin ? bigSize : size) / 2;

  bool get isCollected => state == CoinState.collected;
  bool get isDead => isCollected && _collectAnim >= 1.0;

  void update(double dt) {
    _rotAngle += dt * (isBigCoin ? 1.5 : 3.0);
    _floatTime += dt;
    _floatOffset = sin(_floatTime * 2.5) * 3.0;

    // 코인 비 낙하
    if (vy != 0 && !isCollected) {
      y += vy * dt;
    }

    if (isCollected) {
      _collectAnim = (_collectAnim + dt * 4.0).clamp(0.0, 1.0);
      y -= dt * 80;
    }
  }

  void collect() {
    if (state == CoinState.idle) {
      state = CoinState.collected;
    }
  }

  void draw(Canvas canvas) {
    if (isDead) return;

    final alpha = isCollected ? (1.0 - _collectAnim) : 1.0;
    final drawY = isCollected ? y : y + _floatOffset;
    final scale = isCollected ? (1.0 + _collectAnim * 0.5) : 1.0;
    final r = _radius;

    canvas.save();
    canvas.translate(x, drawY);
    canvas.scale(scale);
    canvas.rotate(_rotAngle);

    // 큰 코인: 황금 테두리 추가 glow
    if (isBigCoin) {
      final outerGlow = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset.zero, r + 6, outerGlow);
    }

    // 코인 glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, r + 3, glowPaint);

    // 코인 원형
    final coinPaint = Paint()
      ..color = (isBigCoin ? const Color(0xFFFF8C00) : const Color(0xFFFFD700))
          .withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, r, coinPaint);

    // 하이라이트
    final hlPaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-r * 0.3, -r * 0.3), r * 0.35, hlPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = const Color(0xFFFFA000).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isBigCoin ? 2.0 : 1.5;
    canvas.drawCircle(Offset.zero, r, borderPaint);

    // 큰 코인: 별표 또는 ★ 심볼
    if (isBigCoin) {
      final linePaint = Paint()
        ..color = const Color(0xFFFFA000).withValues(alpha: alpha * 0.9)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, -r * 0.5), Offset(0, r * 0.5), linePaint);
      canvas.drawLine(Offset(-r * 0.5, 0), Offset(r * 0.5, 0), linePaint);
    } else {
      final linePaint = Paint()
        ..color = const Color(0xFFFFA000).withValues(alpha: alpha * 0.8)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, -r * 0.55), Offset(0, r * 0.55), linePaint);
    }

    canvas.restore();
  }

  Rect get bounds => Rect.fromCenter(
        center: Offset(x, y),
        width: _radius * 2,
        height: _radius * 2,
      );
}
