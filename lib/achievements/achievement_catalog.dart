import 'achievement_model.dart';

/// 전체 업적 목록 정의
List<Achievement> buildAchievementCatalog() => [
      // ── 점수 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'first_flight',
        title: '첫 비행',
        description: '단일 게임 500점 달성',
        iconEmoji: '🚀',
        condition: AchievementCondition.singleRunScore,
        targetValue: 500,
        rewardCoins: 50,
      ),
      Achievement(
        id: 'high_scorer',
        title: '고득점자',
        description: '단일 게임 1500점 달성',
        iconEmoji: '🔥',
        condition: AchievementCondition.singleRunScore,
        targetValue: 1500,
        rewardSkinId: 'flame_core',
        rewardCoins: 100,
      ),
      Achievement(
        id: 'neon_hunter',
        title: '네온 헌터',
        description: '단일 게임 2500점 달성',
        iconEmoji: '⚡',
        condition: AchievementCondition.singleRunScore,
        targetValue: 2500,
        rewardSkinId: 'neon_glitch',
        rewardCoins: 150,
      ),
      Achievement(
        id: 'legend',
        title: '전설',
        description: '누적 총점 10000점 돌파',
        iconEmoji: '👑',
        condition: AchievementCondition.totalScore,
        targetValue: 10000,
        rewardSkinId: 'blackhole_core',
        rewardCoins: 200,
      ),

      // ── 중력 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'gravity_curious',
        title: '중력 탐험가',
        description: '중력 10번 뒤집기',
        iconEmoji: '🔃',
        condition: AchievementCondition.gravityFlipCount,
        targetValue: 10,
        rewardCoins: 30,
      ),
      Achievement(
        id: 'gravity_master',
        title: '중력 마스터',
        description: '중력 50번 뒤집기',
        iconEmoji: '⚡',
        condition: AchievementCondition.gravityFlipCount,
        targetValue: 50,
        rewardSkinId: 'lightning_trail',
        rewardCoins: 80,
      ),
      Achievement(
        id: 'gravity_god',
        title: '중력의 신',
        description: '중력 200번 뒤집기',
        iconEmoji: '🌀',
        condition: AchievementCondition.gravityFlipCount,
        targetValue: 200,
        rewardCoins: 150,
      ),

      // ── 콤보 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'platformer',
        title: '플랫폼 달인',
        description: '연속 플랫폼 30개 착지 (콤보 x30)',
        iconEmoji: '🤖',
        condition: AchievementCondition.consecutivePlatforms,
        targetValue: 30,
        rewardSkinId: 'robot_core',
        rewardCoins: 80,
      ),
      Achievement(
        id: 'fever_king',
        title: '피버 킹',
        description: '콤보 x20 달성',
        iconEmoji: '👾',
        condition: AchievementCondition.maxComboReached,
        targetValue: 20,
        rewardSkinId: 'pixel_core',
        rewardCoins: 100,
      ),

      // ── 플레이 횟수 관련 ───────────────────────────────────────────────────
      Achievement(
        id: 'ghost_player',
        title: '유령 플레이어',
        description: '총 50번 플레이',
        iconEmoji: '👻',
        condition: AchievementCondition.totalGamesPlayed,
        targetValue: 50,
        rewardSkinId: 'ghost_core',
        rewardCoins: 80,
      ),
      Achievement(
        id: 'survivor',
        title: '생존자',
        description: '총 100번 플레이',
        iconEmoji: '🦠',
        condition: AchievementCondition.totalGamesPlayed,
        targetValue: 100,
        rewardSkinId: 'virus_core',
        rewardCoins: 100,
      ),

      // ── 코인 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'coin_collector',
        title: '수집가',
        description: '코인 500개 모으기',
        iconEmoji: '💰',
        condition: AchievementCondition.totalCoinsCollected,
        targetValue: 500,
        rewardCoins: 50,
      ),

      // ── 미션 관련 ──────────────────────────────────────────────────────────
      Achievement(
        id: 'mission_rainbow',
        title: '무지개 전사',
        description: '데일리 미션 50개 달성',
        iconEmoji: '🌈',
        condition: AchievementCondition.dailyMissionsTotal,
        targetValue: 50,
        rewardSkinId: 'rainbow_core',
        rewardCoins: 200,
      ),
    ];
