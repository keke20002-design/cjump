import 'dart:math';
import 'package:flutter/material.dart';

enum CoinState { idle, collected }

/// 인게임에서 플랫폼 위에 스폰되어 플레이어가 수집하는 코인 아이템
class CoinComponent {
  double x;
  double y;
  CoinState state = CoinState.idle;
  double _rotAngle = 0.0;
  double _floatOffset = 0.0;
  double _floatTime = 0.0;
  double _collectAnim = 0.0; // 0..1 수집 애니메이션

  static const double size = 14.0;
  static const double magnetRange = 40.0;

  CoinComponent({required this.x, required this.y});

  bool get isCollected => state == CoinState.collected;
  bool get isDead => isCollected && _collectAnim >= 1.0;

  void update(double dt) {
    _rotAngle += dt * 3.0;
    _floatTime += dt;
    _floatOffset = sin(_floatTime * 2.5) * 3.0;

    if (isCollected) {
      _collectAnim = (_collectAnim + dt * 4.0).clamp(0.0, 1.0);
      y -= dt * 60; // 수집 시 위로 솟아오름
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
    final drawY = y + _floatOffset;
    final scale = isCollected ? (1.0 + _collectAnim * 0.5) : 1.0;

    canvas.save();
    canvas.translate(x, drawY);
    canvas.scale(scale);
    canvas.rotate(_rotAngle);

    // 코인 원형
    final coinPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset.zero, size / 2 + 3, glowPaint);
    canvas.drawCircle(Offset.zero, size / 2, coinPaint);

    // 안쪽 하이라이트
    final hlPaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(-2, -2), size / 4, hlPaint);

    // 테두리
    final borderPaint = Paint()
      ..color = const Color(0xFFFFA000).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, size / 2, borderPaint);

    // 동전 기호 (작은 선)
    final linePaint = Paint()
      ..color = const Color(0xFFFFA000).withValues(alpha: alpha * 0.8)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -3), const Offset(0, 3), linePaint);

    canvas.restore();
  }

  Rect get bounds => Rect.fromCenter(
        center: Offset(x, y),
        width: size,
        height: size,
      );
}
