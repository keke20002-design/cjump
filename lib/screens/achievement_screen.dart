import 'package:flutter/material.dart';
import '../achievements/achievement_model.dart';
import '../achievements/achievement_catalog.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  Color _condColor(AchievementCondition c) {
    switch (c) {
      case AchievementCondition.singleRunScore:
      case AchievementCondition.totalScore:
        return const Color(0xFFFFD700);
      case AchievementCondition.gravityFlipCount:
        return const Color(0xFFAB47BC);
      case AchievementCondition.consecutivePlatforms:
      case AchievementCondition.maxComboReached:
        return const Color(0xFF69FF47);
      case AchievementCondition.totalGamesPlayed:
        return const Color(0xFF4FC3F7);
      case AchievementCondition.totalCoinsCollected:
        return const Color(0xFFFFD700);
      case AchievementCondition.dailyMissionsTotal:
        return const Color(0xFFFF8A65);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = buildAchievementCatalog();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text(
          '업적',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final a = achievements[i];
          final color = _condColor(a.condition);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: a.isCompleted ? 0.1 : 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: a.isCompleted
                    ? color.withValues(alpha: 0.6)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                // 이모지
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (a.isCompleted ? color : Colors.grey)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      a.isCompleted ? a.iconEmoji : '🔒',
                      style: TextStyle(
                          fontSize: 22,
                          color: a.isCompleted ? null : Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: TextStyle(
                          color: a.isCompleted ? Colors.white : Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.description,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      // 진행도 바
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: a.progressFraction,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            a.isCompleted ? color : color.withValues(alpha: 0.5),
                          ),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${a.currentProgress} / ${a.targetValue}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                // 보상
                if (a.rewardCoins > 0 || a.rewardSkinId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a.rewardSkinId != null
                          ? '🎨+${a.rewardCoins > 0 ? '${a.rewardCoins}💰' : ''}'
                          : '+${a.rewardCoins}💰',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
