import 'package:flutter/material.dart';
import '../game/antigravity_game.dart';
import '../components/magnet_item.dart';
import 'gravity_indicator.dart';

class HudOverlay extends StatelessWidget {
  final AntiGravityGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (_, __) {
        return Stack(
          children: [
            // 코인 비 배너
            if (game.coinRainActive)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'COIN RAIN!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.circle, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

            // 보너스 찬스 배너
            if (game.bonusChanceActive)
              Positioned(
                top: game.coinRainActive ? 126 : 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0030).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: const Color(0xFFE040FB), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFAB47BC).withValues(alpha: 0.7),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            color: Color(0xFFE040FB), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'BONUS CHANCE!',
                          style: TextStyle(
                            color: Color(0xFFE040FB),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                  color: Color(0xFFAB47BC), blurRadius: 10),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.star_rounded,
                            color: Color(0xFFE040FB), size: 18),
                      ],
                    ),
                  ),
                ),
              ),

            // 쉴드 타이머 (활성 시)
            if (game.isShielded)
              Positioned(
                top: game.coinRainActive ? 160 : game.bonusChanceActive ? 126 : 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003040).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded,
                            color: Color(0xFF00E5FF), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'SHIELD ${(game.shieldFraction * 5).toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 자석 타이머 (활성 시)
            if (game.magnetActive)
              Positioned(
                top: game.coinRainActive ? 126 : 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.electric_bolt, color: Color(0xFF00E5FF), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'MAGNET ${(game.magnetFraction * MagnetItem.magnetDuration).toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gravity indicator + cooldown (left)
                GravityIndicator(game: game),

                // Score (center)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${game.scoreManager.displayScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // High score + coin (right)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BEST',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${game.scoreManager.displayHighScore}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle,
                              color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${game.coinManager.sessionCoins}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
          ],
        );
      },
    );
  }
}
