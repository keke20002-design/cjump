import 'package:flutter/material.dart';

enum SkinCategory { basic, effect, theme }
enum UnlockType { score, achievement, coin, combo, missions, free }

enum TrailType { none, lightning, starDust, flame, ice, blackHole, aurora, ghost }
enum ParticleType { none, spark, star, ember, snowflake, glitch, pixel, rainbow }

class CharacterSkin {
  final String id;
  final String displayName;
  final SkinCategory category;
  final UnlockType unlockType;
  final int unlockValue; // score / coin cost / combo / achievement id ref
  final String? unlockAchievementId;
  final bool isDefault;
  bool isUnlocked;

  // Visual config
  final Color coreColor;
  final Color? glowColor;
  final TrailType trailEffect;
  final ParticleType particleEffect;
  final bool isPixelStyle;  // robot_core, pixel_core
  final bool isGhostStyle;  // ghost_core (반투명)
  final bool isRainbow;     // rainbow_core (색상 사이클)

  CharacterSkin({
    required this.id,
    required this.displayName,
    required this.category,
    required this.unlockType,
    required this.unlockValue,
    this.unlockAchievementId,
    this.isDefault = false,
    required this.isUnlocked,
    required this.coreColor,
    this.glowColor,
    this.trailEffect = TrailType.none,
    this.particleEffect = ParticleType.none,
    this.isPixelStyle = false,
    this.isGhostStyle = false,
    this.isRainbow = false,
  });

  String get unlockDescription {
    switch (unlockType) {
      case UnlockType.free:
        return '기본 스킨';
      case UnlockType.score:
        return '점수 $unlockValue점 달성';
      case UnlockType.coin:
        return '💰 $unlockValue 코인';
      case UnlockType.achievement:
        return '업적 달성 보상';
      case UnlockType.combo:
        return '콤보 x$unlockValue 달성';
      case UnlockType.missions:
        return '미션 $unlockValue개 달성';
    }
  }
}
