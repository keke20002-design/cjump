import 'package:flutter/material.dart';
import 'skin_model.dart';
import '../economy/persistence_manager.dart';

/// 전체 스킨 카탈로그 빌드 + 해금 상태 로드
List<CharacterSkin> buildSkinCatalog() {
  final pm = PersistenceManager.instance;
  final unlocked = pm.unlockedSkins;

  return [
    // ── Basic ──────────────────────────────────────────────────────────────
    CharacterSkin(
      id: 'green_core',
      displayName: 'Green Core',
      category: SkinCategory.basic,
      unlockType: UnlockType.free,
      unlockValue: 0,
      isDefault: true,
      isUnlocked: true,
      coreColor: const Color(0xFF00E676),
    ),
    CharacterSkin(
      id: 'red_core',
      displayName: 'Red Core',
      category: SkinCategory.basic,
      unlockType: UnlockType.score,
      unlockValue: 300,
      isUnlocked: unlocked.contains('red_core'),
      coreColor: const Color(0xFFFF1744),
      glowColor: const Color(0xFFFF6B6B),
    ),
    CharacterSkin(
      id: 'neon_core',
      displayName: 'Neon Core',
      category: SkinCategory.basic,
      unlockType: UnlockType.score,
      unlockValue: 700,
      isUnlocked: unlocked.contains('neon_core'),
      coreColor: const Color(0xFF00FFFF),
      glowColor: const Color(0xFF00FFFF),
    ),
    CharacterSkin(
      id: 'shadow_core',
      displayName: 'Shadow Core',
      category: SkinCategory.basic,
      unlockType: UnlockType.coin,
      unlockValue: 150,
      isUnlocked: unlocked.contains('shadow_core'),
      coreColor: const Color(0xFF424242),
      glowColor: const Color(0xFF7C4DFF),
    ),

    // ── Effect ─────────────────────────────────────────────────────────────
    CharacterSkin(
      id: 'lightning_trail',
      displayName: 'Lightning Trail',
      category: SkinCategory.effect,
      unlockType: UnlockType.adUnlock,
      unlockValue: 0,
      isUnlocked: unlocked.contains('lightning_trail'),
      coreColor: const Color(0xFFFFD600),
      glowColor: const Color(0xFFFFFF00),
      trailEffect: TrailType.lightning,
      particleEffect: ParticleType.spark,
    ),
    CharacterSkin(
      id: 'stardust_trail',
      displayName: 'Stardust',
      category: SkinCategory.effect,
      unlockType: UnlockType.coin,
      unlockValue: 300,
      isUnlocked: unlocked.contains('stardust_trail'),
      coreColor: const Color(0xFFE040FB),
      glowColor: const Color(0xFFCE93D8),
      trailEffect: TrailType.starDust,
      particleEffect: ParticleType.star,
    ),
    CharacterSkin(
      id: 'flame_core',
      displayName: 'Flame Core',
      category: SkinCategory.effect,
      unlockType: UnlockType.achievement,
      unlockValue: 0,
      unlockAchievementId: 'high_scorer',
      isUnlocked: unlocked.contains('flame_core'),
      coreColor: const Color(0xFFFF6D00),
      glowColor: const Color(0xFFFFAB40),
      trailEffect: TrailType.flame,
      particleEffect: ParticleType.ember,
    ),
    CharacterSkin(
      id: 'ice_core',
      displayName: 'Ice Core',
      category: SkinCategory.effect,
      unlockType: UnlockType.coin,
      unlockValue: 200,
      isUnlocked: unlocked.contains('ice_core'),
      coreColor: const Color(0xFF40C4FF),
      glowColor: const Color(0xFFB3E5FC),
      trailEffect: TrailType.ice,
      particleEffect: ParticleType.snowflake,
    ),

    // ── Theme ──────────────────────────────────────────────────────────────
    CharacterSkin(
      id: 'blackhole_core',
      displayName: 'Black Hole Core',
      category: SkinCategory.theme,
      unlockType: UnlockType.adUnlock,
      unlockValue: 0,
      isUnlocked: unlocked.contains('blackhole_core'),
      coreColor: const Color(0xFF000000),
      glowColor: const Color(0xFFAA00FF),
      trailEffect: TrailType.blackHole,
      particleEffect: ParticleType.glitch,
    ),
    CharacterSkin(
      id: 'virus_core',
      displayName: 'Virus Core',
      category: SkinCategory.theme,
      unlockType: UnlockType.achievement,
      unlockValue: 0,
      unlockAchievementId: 'survivor',
      isUnlocked: unlocked.contains('virus_core'),
      coreColor: const Color(0xFF76FF03),
      glowColor: const Color(0xFFCCFF90),
      particleEffect: ParticleType.glitch,
    ),
    CharacterSkin(
      id: 'gold_core',
      displayName: 'Gold Core',
      category: SkinCategory.theme,
      unlockType: UnlockType.coin,
      unlockValue: 1000,
      isUnlocked: unlocked.contains('gold_core'),
      coreColor: const Color(0xFFFFD700),
      glowColor: const Color(0xFFFFF176),
      trailEffect: TrailType.starDust,
      particleEffect: ParticleType.star,
    ),
    CharacterSkin(
      id: 'robot_core',
      displayName: 'Robot Core',
      category: SkinCategory.theme,
      unlockType: UnlockType.achievement,
      unlockValue: 0,
      unlockAchievementId: 'platformer',
      isUnlocked: unlocked.contains('robot_core'),
      coreColor: const Color(0xFF90A4AE),
      glowColor: const Color(0xFFCFD8DC),
      isPixelStyle: true,
    ),
    // ── v2 스킨 ───────────────────────────────────────────────────────────
    CharacterSkin(
      id: 'ghost_core',
      displayName: 'Ghost Core',
      category: SkinCategory.theme,
      unlockType: UnlockType.achievement,
      unlockValue: 0,
      unlockAchievementId: 'ghost_player',
      isUnlocked: unlocked.contains('ghost_core'),
      coreColor: const Color(0xFFB3E5FC).withValues(alpha: 0.5),
      glowColor: const Color(0xFF80DEEA),
      trailEffect: TrailType.ghost,
      isGhostStyle: true,
    ),
    CharacterSkin(
      id: 'pixel_core',
      displayName: 'Pixel Core',
      category: SkinCategory.theme,
      unlockType: UnlockType.achievement,
      unlockValue: 0,
      unlockAchievementId: 'fever_king',
      isUnlocked: unlocked.contains('pixel_core'),
      coreColor: const Color(0xFF69FF47),
      glowColor: const Color(0xFF1DE9B6),
      isPixelStyle: true,
    ),
    CharacterSkin(
      id: 'neon_glitch',
      displayName: 'Neon Glitch',
      category: SkinCategory.theme,
      unlockType: UnlockType.achievement,
      unlockValue: 0,
      unlockAchievementId: 'neon_hunter',
      isUnlocked: unlocked.contains('neon_glitch'),
      coreColor: const Color(0xFF00E5FF),
      glowColor: const Color(0xFFFF1744),
      particleEffect: ParticleType.glitch,
    ),
    CharacterSkin(
      id: 'rainbow_core',
      displayName: 'Rainbow Core',
      category: SkinCategory.theme,
      unlockType: UnlockType.achievement,
      unlockValue: 0,
      unlockAchievementId: 'mission_rainbow',
      isUnlocked: unlocked.contains('rainbow_core'),
      coreColor: const Color(0xFFFF1744),
      glowColor: const Color(0xFFFFD700),
      particleEffect: ParticleType.rainbow,
      isRainbow: true,
    ),
  ];
}

/// 점수/통계 기반으로 자동 해금 체크 후 저장
Future<List<String>> checkScoreUnlocks(int highScore) async {
  final pm = PersistenceManager.instance;
  final unlocked = List<String>.from(pm.unlockedSkins);
  final newlyUnlocked = <String>[];

  final scoreUnlocks = {
    'red_core': 300,
    'neon_core': 700,
  };

  for (final entry in scoreUnlocks.entries) {
    if (!unlocked.contains(entry.key) && highScore >= entry.value) {
      unlocked.add(entry.key);
      newlyUnlocked.add(entry.key);
    }
  }

  if (newlyUnlocked.isNotEmpty) {
    await pm.setUnlockedSkins(unlocked);
  }
  return newlyUnlocked;
}
