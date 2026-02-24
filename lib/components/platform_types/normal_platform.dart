import 'dart:ui';
import 'package:flutter/material.dart';
import '../platform.dart';
import '../../utils/constants.dart';

class NormalPlatform extends GamePlatform {
  NormalPlatform({required super.x, required super.y})
      : super(
          width: kPlatformWidth,
          height: kPlatformHeight,
          type: PlatformType.normal,
        );

  @override
  Color get baseColor => const Color(0xFF66BB6A);

  @override
  bool onPlayerBounce() => true;

  @override
  void draw(Canvas canvas) => drawBase(canvas);
}
