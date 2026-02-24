import 'dart:ui';
import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';

class SpikePlatform extends GamePlatform {
  SpikePlatform({required super.x, required super.y})
      : super(
          width: kPlatformWidth,
          height: kPlatformHeight + 8,
          type: PlatformType.spike,
        );

  @override
  Color get baseColor => const Color(0xFFEF5350);

  @override
  bool onPlayerBounce() => false; // triggers game over instead

  @override
  void draw(Canvas canvas) {
    drawBase(canvas);

    // Draw spikes on top
    final spikePaint = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.fill;

    const spikeCount = 5;
    final spikeWidth = width / spikeCount;
    for (int i = 0; i < spikeCount; i++) {
      final spikeX = (x - width / 2) + i * spikeWidth;
      final path = Path()
        ..moveTo(spikeX, y - height / 2)
        ..lineTo(spikeX + spikeWidth / 2, y - height / 2 - 8)
        ..lineTo(spikeX + spikeWidth, y - height / 2)
        ..close();
      canvas.drawPath(path, spikePaint);
    }
  }
}
