import 'dart:math';
import 'package:flutter/material.dart';
import 'skin_model.dart';

/// 선택된 스킨에 따라 플레이어 캐릭터를 다르게 그리는 렌더러
class SkinRenderer {
  final CharacterSkin skin;
  double _rainbowHue = 0.0;
  double _glowPulse = 0.0;
  double _effectTimer = 0.0;

  SkinRenderer(this.skin);

  void update(double dt) {
    _rainbowHue = (_rainbowHue + dt * 80) % 360;
    _glowPulse += dt * (2 * pi / 0.8); // 0.8s cycle
    _effectTimer += dt;
  }

  Color get _effectiveColor {
    if (skin.isRainbow) {
      return HSVColor.fromAHSV(1.0, _rainbowHue, 0.9, 1.0).toColor();
    }
    return skin.coreColor;
  }

  void draw(Canvas canvas, double x, double y, bool isNormalGravity) {
    final color = _effectiveColor;
    final glow = skin.glowColor ?? color;
    final pulseFactor = skin.id == 'neon_core'
        ? 0.5 + 0.5 * sin(_glowPulse)
        : 0.0;

    // ── Aura Effects (Behind Core) ──
    _drawAura(canvas, x, y, color, glow);

    if (skin.isPixelStyle) {
      _drawPixel(canvas, x, y, color, glow, isNormalGravity);
    } else if (skin.isGhostStyle) {
      _drawGhost(canvas, x, y, color, glow);
    } else {
      _drawCore(canvas, x, y, color, glow, pulseFactor);
    }
  }

  void _drawAura(Canvas canvas, double x, double y, Color color, Color glow) {
    switch (skin.trailEffect) {
      case TrailType.lightning:
        _drawLightningAura(canvas, x, y, glow);
        break;
      case TrailType.starDust:
        _drawStardustAura(canvas, x, y, glow);
        break;
      case TrailType.flame:
        _drawFlameAura(canvas, x, y, glow);
        break;
      case TrailType.ice:
        _drawIceAura(canvas, x, y, glow);
        break;
      default:
        break;
    }
  }

  void _drawLightningAura(Canvas canvas, double x, double y, Color glow) {
    const count = 4;
    final angleBase = _effectTimer * 5.5;
    final paint = Paint()
      ..color = glow.withValues(alpha: 1.0)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < count; i++) {
      final angle = angleBase + (i * 2 * pi / count);
      final r = 28.0 + sin(_effectTimer * 6 + i) * 6;
      final bx = x + cos(angle) * r;
      final by = y + sin(angle) * r;

      // Draw a larger zig-zag
      final path = Path()..moveTo(bx, by);
      const zR = 10.0;
      path.lineTo(bx + cos(angle + 0.6) * zR, by + sin(angle + 0.6) * zR);
      path.lineTo(bx - cos(angle - 0.3) * zR, by - sin(angle - 0.3) * zR);
      
      canvas.drawPath(path, paint);
    }
  }

  void _drawStardustAura(Canvas canvas, double x, double y, Color glow) {
    const count = 9;
    final paint = Paint()..color = glow.withValues(alpha: 0.7);

    for (int i = 0; i < count; i++) {
      final t = _effectTimer + i * 1.5;
      final r = 22.0 + sin(t * 2.5) * 8;
      final ang = t * 1.8 + i;
      final px = x + cos(ang) * r;
      final py = y + sin(ang) * r;
      final size = 5.0 + cos(t * 3.5) * 2.5;

      canvas.drawCircle(Offset(px, py), size, paint);
      
      // Floating outer dust
      final r2 = 36.0 + cos(t * 1.8) * 12;
      final px2 = x + cos(ang * 0.8) * r2;
      final py2 = y + sin(ang * 0.8) * r2;
      canvas.drawCircle(Offset(px2, py2), 3.0, Paint()..color = glow.withValues(alpha: 0.4));
    }
  }

  void _drawFlameAura(Canvas canvas, double x, double y, Color glow) {
    const count = 7;
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (int i = 0; i < count; i++) {
      final t = _effectTimer * 3.5 + i * 0.9;
      final offset = (t % 1.0); // 0..1
      final r = 12.0 + offset * 24.0;
      final ang = -pi / 2 + (i - 3) * 0.5 + sin(t) * 0.3;
      final px = x + cos(ang) * r;
      final py = y + sin(ang) * r;
      
      paint.color = glow.withValues(alpha: (1.0 - offset) * 0.9);
      canvas.drawCircle(Offset(px, py), 9.0 * (1.0 - offset), paint);
    }
  }

  void _drawIceAura(Canvas canvas, double x, double y, Color glow) {
    const count = 6;
    final angleBase = _effectTimer * 1.2;
    final paint = Paint()
      ..color = glow.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    for (int i = 0; i < count; i++) {
      final ang = angleBase + (i * 2 * pi / count);
      final r = 26.0 + sin(_effectTimer * 3 + i) * 5;
      final px = x + cos(ang) * r;
      final py = y + sin(ang) * r;

      // Ice diamond/shard (Larger)
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(ang + pi / 4);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12, height: 12), paint);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 6), 
          paint..style = PaintingStyle.fill..color = glow.withValues(alpha: 0.4));
      canvas.restore();
    }
  }

  void _drawCore(Canvas canvas, double x, double y, Color color, Color glow, double pulse) {
    const r = 16.0;

    // 외부 글로우
    if (skin.glowColor != null) {
      final glowAlpha = 0.25 + pulse * 0.35;
      final glowPaint = Paint()
        ..color = glow.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(x, y), r + 6 + pulse * 4, glowPaint);
    }

    // 메인 원
    final bodyPaint = Paint()..color = color;
    canvas.drawCircle(Offset(x, y), r, bodyPaint);

    // 하이라이트
    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(x - r * 0.3, y - r * 0.3), r * 0.4, hlPaint);

    // 눈
    _drawEyes(canvas, x, y, r, isNormalGravity: true);
  }

  void _drawPixel(Canvas canvas, double x, double y, Color color, Color glow, bool isNormal) {
    const s = 28.0;
    final rect = Rect.fromCenter(center: Offset(x, y), width: s, height: s);

    // 픽셀 바디
    final bodyPaint = Paint()..color = color;
    canvas.drawRect(rect, bodyPaint);

    // 글로우
    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(rect.inflate(4), glowPaint);

    // 안테나 (로봇 스타일)
    final antennaPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(x, y - s / 2),
      Offset(x, y - s / 2 - 8),
      antennaPaint,
    );
    canvas.drawCircle(Offset(x, y - s / 2 - 10), 3, antennaPaint);

    // 픽셀 눈 (사각형)
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRect(Rect.fromLTWH(x - 8, y - 4, 5, 5), eyePaint);
    canvas.drawRect(Rect.fromLTWH(x + 3, y - 4, 5, 5), eyePaint);
  }

  void _drawGhost(Canvas canvas, double x, double y, Color color, Color glow) {
    const r = 18.0;

    // 반투명 글로우
    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(x, y), r + 10, glowPaint);

    // 반투명 바디
    final bodyPaint = Paint()..color = color.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(x, y), r, bodyPaint);

    // 눈 (반투명)
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(x - 5, y - 2), 4, eyePaint);
    canvas.drawCircle(Offset(x + 5, y - 2), 4, eyePaint);
  }

  void _drawEyes(Canvas canvas, double x, double y, double r,
      {required bool isNormalGravity}) {
    final eyeY = y + (isNormalGravity ? -r * 0.15 : r * 0.15);
    final eyePaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(x - r * 0.3, eyeY), r * 0.22, eyePaint);
    canvas.drawCircle(Offset(x + r * 0.3, eyeY), r * 0.22, eyePaint);

    final pupilPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(x - r * 0.28, eyeY + 1), r * 0.1, pupilPaint);
    canvas.drawCircle(Offset(x + r * 0.28, eyeY + 1), r * 0.1, pupilPaint);
  }
}

/// 트레일 이펙트 파티클
class TrailParticle {
  double x, y;
  double vx, vy;
  final Color color;
  final TrailType type;
  double life = 1.0;
  final double _decay;

  TrailParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.type,
  }) : _decay = type == TrailType.flame ? 3.0 : 2.5;

  bool get isDead => life <= 0;

  void update(double dt, bool isNormal) {
    x += vx * dt;
    y += vy * dt;
    // 중력 방향에 따라 파티클 방향 조정
    if (type == TrailType.flame || type == TrailType.starDust) {
      vy += (isNormal ? -100 : 100) * dt;
    }
    life -= _decay * dt;
  }

  void draw(Canvas canvas) {
    final alpha = life.clamp(0.0, 1.0);
    final size = 4.0 * life;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..maskFilter = type == TrailType.lightning
          ? const MaskFilter.blur(BlurStyle.normal, 2)
          : null;
    canvas.drawCircle(Offset(x, y), size, paint);
  }
}
