import 'package:flutter/material.dart';
import '../game/antigravity_game.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  final AntiGravityGame game;
  const MenuScreen({super.key, required this.game});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  // Bounce (logo float)
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  // Pulse (BEST score)
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  bool _tiltEnabled = true;

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -18).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
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
            'assets/images/main_s.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1B2A), Color(0xFF2E4F7C)],
                ),
              ),
            ),
          ),

          // ── Dark global overlay ──
          Container(color: Colors.black.withValues(alpha: 0.38)),

          // ── Top-left suppression: dim competing background objects ──
          Positioned(
            top: 0,
            left: 0,
            width: 200,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.0,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo hero with glow ──
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _bounceAnim.value),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.30),
                            blurRadius: 60,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 254, // +15% from 220
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 254,
                          height: 140,
                          child: Center(
                            child: Text(
                              'ZeroFlip',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Slogan — neon style ──
                const Text(
                  'Up Is Down',
                  style: TextStyle(
                    color: Color(0xFF82C8FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Color(0xFF4A90D9),
                        blurRadius: 12,
                      ),
                      Shadow(
                        color: Color(0xFF82C8FF),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── PLAY button ──
                _MenuButton(
                  label: 'PLAY',
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    widget.game.useTilt = _tiltEnabled;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(game: widget.game),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── BEST score pill with pulse ──
                ListenableBuilder(
                  listenable: widget.game,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'BEST ',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        // Pulsing score number
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: Text(
                              '${widget.game.scoreManager.displayHighScore}',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.amber
                                        .withValues(alpha: (_pulseAnim.value - 1.0) * 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Tilt toggle (bottom) ──
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_rotation,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Tilt Control',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _tiltEnabled,
                        onChanged: (v) =>
                            setState(() => _tiltEnabled = v),
                        activeThumbColor: const Color(0xFF4A90D9),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
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
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
