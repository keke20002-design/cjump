import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Game background with:
/// - play_g.png  →  normal gravity state
/// - play_N.png  →  antigravity state
/// - 0.2-second smooth crossfade between them
class BackgroundComponent {
  ui.Image? _imgNormal;   // play_g.png
  ui.Image? _imgAnti;     // play_N.png

  /// 0.0 = play_g fully visible, 1.0 = play_N fully visible
  double _blend = 0.0;

  bool _initialized = false;

  // ─── Init ─────────────────────────────────────────────────────────────────

  void init(double screenWidth, double screenHeight) {
    if (_initialized) return;
    _initialized = true;
    _loadImages();
  }

  Future<void> _loadImages() async {
    _imgNormal ??= await _loadAsset('assets/images/play_g.png');
    _imgAnti   ??= await _loadAsset('assets/images/play_N.png');
  }

  static Future<ui.Image> _loadAsset(String path) async {
    final data  = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  /// Called every frame. [isAntigravity] drives the blend target.
  void update(double dt, bool isAntigravity) {
    const kFadeSpeed = 1.0 / 0.2; // complete in 0.2 s
    final target = isAntigravity ? 1.0 : 0.0;
    if (_blend < target) {
      _blend = (_blend + dt * kFadeSpeed).clamp(0.0, 1.0);
    } else if (_blend > target) {
      _blend = (_blend - dt * kFadeSpeed).clamp(0.0, 1.0);
    }
  }

  // ─── Draw ─────────────────────────────────────────────────────────────────

  void draw(Canvas canvas, Size size, double cameraY) {
    if (_imgNormal == null && _imgAnti == null) {
      // Images still loading — fallback colour crossfade
      final col = Color.lerp(
        const Color(0xFFFAFAFF),
        const Color(0xFF0D1B2A),
        _blend,
      )!;
      canvas.drawRect(Offset.zero & size, Paint()..color = col);
      return;
    }

    // Draw normal (play_g) layer
    if (_imgNormal != null && _blend < 1.0) {
      _drawCover(canvas, size, _imgNormal!, 1.0 - _blend);
    }

    // Draw antigravity (play_N) layer on top
    if (_imgAnti != null && _blend > 0.0) {
      _drawCover(canvas, size, _imgAnti!, _blend);
    }
  }

  void _drawCover(Canvas canvas, Size size, ui.Image img, double opacity) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));

    final iW = img.width.toDouble();
    final iH = img.height.toDouble();
    final scale = max(size.width / iW, size.height / iH);
    final dW  = iW * scale;
    final dH  = iH * scale;
    final dx  = (size.width  - dW) / 2;
    final dy  = (size.height - dH) / 2;

    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, iW, iH),
      Rect.fromLTWH(dx, dy, dW, dH),
      paint,
    );
  }
}
