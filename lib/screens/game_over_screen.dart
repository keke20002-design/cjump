import 'package:flutter/material.dart';
import '../game/antigravity_game.dart';
import 'menu_screen.dart';
import 'game_screen.dart';

class GameOverScreen extends StatefulWidget {
  final AntiGravityGame game;
  const GameOverScreen({super.key, required this.game});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countCtrl;
  late final Animation<double> _countAnim;

  int get _finalScore => widget.game.scoreManager.displayScore;
  int get _highScore => widget.game.scoreManager.displayHighScore;
  bool get _isNewHighScore => _finalScore >= _highScore && _finalScore > 0;

  @override
  void initState() {
    super.initState();
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countAnim = Tween<double>(begin: 0, end: _finalScore.toDouble()).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut),
    );
    // Start after a short delay so the screen settles first
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _countCtrl.forward();
    });
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──
          Image.asset(
            'assets/images/game_over.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0030),
                    Color(0xFF2D1B4E),
                    Color(0xFF0D1B2A)
                  ],
                ),
              ),
            ),
          ),

          // ── Dark overlay — stronger to keep UI readable ──
          Container(color: Colors.black.withValues(alpha: 0.60)),

          // ── Content ──
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── GAME OVER title ──
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(color: Color(0xFFAB47BC), blurRadius: 30),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Score card ──
                  Container(
                    width: 280,
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // SCORE label
                        const Text(
                          'SCORE',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ── Count-up number ──
                        AnimatedBuilder(
                          animation: _countAnim,
                          builder: (_, __) => Text(
                            '${_countAnim.value.round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── NEW HIGH SCORE badge (below number) ──
                        if (_isNewHighScore) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star,
                                    color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'NEW HIGH SCORE',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.star,
                                    color: Colors.amber, size: 14),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Divider(color: Colors.white12, height: 8),
                        const SizedBox(height: 8),

                        // BEST row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'BEST ',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 14),
                            ),
                            Text(
                              '$_highScore',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── PLAY AGAIN — primary button ──
                  _GameOverButton(
                    label: 'PLAY AGAIN',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      widget.game.startGame();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(game: widget.game),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── MENU — subtle text button ──
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => MenuScreen(game: widget.game),
                        ),
                        (_) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                    ),
                    child: const Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GameOverButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GameOverButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
