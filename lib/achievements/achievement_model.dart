// 업적 조건 종류
enum AchievementCondition {
  totalScore,           // 누적 총점
  singleRunScore,       // 단일 게임 점수
  gravityFlipCount,     // 중력 뒤집기 횟수 (누적)
  consecutivePlatforms, // 연속 플랫폼 착지 (콤보)
  totalGamesPlayed,     // 총 플레이 횟수
  totalCoinsCollected,  // 누적 코인 수집
  maxComboReached,      // 최대 콤보 달성
  dailyMissionsTotal,   // 데일리 미션 총 달성 수
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final AchievementCondition condition;
  final int targetValue;
  bool isCompleted;
  int currentProgress;

  // Reward
  final String? rewardSkinId;
  final int rewardCoins;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.condition,
    required this.targetValue,
    this.rewardSkinId,
    this.rewardCoins = 0,
    this.isCompleted = false,
    this.currentProgress = 0,
  });

  double get progressFraction =>
      (currentProgress / targetValue).clamp(0.0, 1.0);
}
