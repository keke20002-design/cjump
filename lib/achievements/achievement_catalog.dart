import 'achievement_model.dart';

/// 전체 업적 목록 정의
List<Achievement> buildAchievementCatalog() => [
      // ── 점수 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'first_flight',
        title: 'First Flight',
        description: 'Single run score 500',
        iconEmoji: '🚀',
        condition: AchievementCondition.singleRunScore,
        targetValue: 500,
        rewardCoins: 50,
      ),
      Achievement(
        id: 'high_scorer',
        title: 'High Scorer',
        description: 'Single run score 1500',
        iconEmoji: '🔥',
        condition: AchievementCondition.singleRunScore,
        targetValue: 1500,
        rewardSkinId: 'flame_core',
        rewardCoins: 100,
      ),
      Achievement(
        id: 'neon_hunter',
        title: 'Neon Hunter',
        description: 'Single run score 2500',
        iconEmoji: '⚡',
        condition: AchievementCondition.singleRunScore,
        targetValue: 2500,
        rewardSkinId: 'neon_glitch',
        rewardCoins: 150,
      ),
      Achievement(
        id: 'legend',
        title: 'Legend',
        description: 'Total score over 10000',
        iconEmoji: '👑',
        condition: AchievementCondition.totalScore,
        targetValue: 10000,
        rewardSkinId: 'blackhole_core',
        rewardCoins: 200,
      ),

      // ── 중력 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'gravity_curious',
        title: 'Gravity Explorer',
        description: 'Flip gravity 10 times',
        iconEmoji: '🔃',
        condition: AchievementCondition.gravityFlipCount,
        targetValue: 10,
        rewardCoins: 30,
      ),
      Achievement(
        id: 'gravity_master',
        title: 'Gravity Master',
        description: 'Flip gravity 50 times',
        iconEmoji: '⚡',
        condition: AchievementCondition.gravityFlipCount,
        targetValue: 50,
        rewardSkinId: 'lightning_trail',
        rewardCoins: 80,
      ),
      Achievement(
        id: 'gravity_god',
        title: 'God of Gravity',
        description: 'Flip gravity 200 times',
        iconEmoji: '🌀',
        condition: AchievementCondition.gravityFlipCount,
        targetValue: 200,
        rewardCoins: 150,
      ),

      // ── 콤보 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'platformer',
        title: 'Platform Master',
        description: 'Land on 30 platforms consecutively (Combo x30)',
        iconEmoji: '🤖',
        condition: AchievementCondition.consecutivePlatforms,
        targetValue: 30,
        rewardSkinId: 'robot_core',
        rewardCoins: 80,
      ),
      Achievement(
        id: 'fever_king',
        title: 'Fever King',
        description: 'Reach Combo x20',
        iconEmoji: '👾',
        condition: AchievementCondition.maxComboReached,
        targetValue: 20,
        rewardSkinId: 'pixel_core',
        rewardCoins: 100,
      ),

      // ── 플레이 횟수 관련 ───────────────────────────────────────────────────
      Achievement(
        id: 'ghost_player',
        title: 'Ghost Player',
        description: 'Play 50 times',
        iconEmoji: '👻',
        condition: AchievementCondition.totalGamesPlayed,
        targetValue: 50,
        rewardSkinId: 'ghost_core',
        rewardCoins: 80,
      ),
      Achievement(
        id: 'survivor',
        title: 'Survivor',
        description: 'Play 100 times',
        iconEmoji: '🦠',
        condition: AchievementCondition.totalGamesPlayed,
        targetValue: 100,
        rewardSkinId: 'virus_core',
        rewardCoins: 100,
      ),

      // ── 코인 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'coin_collector',
        title: 'Collector',
        description: 'Collect 500 coins',
        iconEmoji: '💰',
        condition: AchievementCondition.totalCoinsCollected,
        targetValue: 500,
        rewardCoins: 50,
      ),

      // ── 미션 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'mission_rainbow',
        title: 'Rainbow Warrior',
        description: 'Complete 50 daily missions',
        iconEmoji: '🌈',
        condition: AchievementCondition.dailyMissionsTotal,
        targetValue: 50,
        rewardSkinId: 'rainbow_core',
        rewardCoins: 200,
      ),
    ];
