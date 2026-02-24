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
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;
  bool _tiltEnabled = true;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image
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
          // Dark overlay for text readability
          Container(color: Colors.black.withValues(alpha: 0.38)),
          // Content
          SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated bouncing character
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnim.value),
                    child: CustomPaint(
                      size: const Size(80, 80),
                      painter: _MenuCharacterPainter(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'ZeroFlip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Color(0xFF4A90D9),
                      blurRadius: 20,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const Text(
                'Up Is Down',
                style: TextStyle(
                  color: Color(0xFF4A90D9),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 12),

              // Tagline
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'TAP TO FLIP GRAVITY • TILT TO MOVE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const Spacer(),

              // PLAY button
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

              const SizedBox(height: 16),

              // High Score display
              ListenableBuilder(
                listenable: widget.game,
                builder: (_, __) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'BEST: ',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        Text(
                          '${widget.game.scoreManager.displayHighScore}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Tilt toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Tilt Control',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _tiltEnabled,
                    onChanged: (v) => setState(() => _tiltEnabled = v),
                    activeThumbColor: const Color(0xFF4A90D9),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),  // SafeArea
        ],  // Stack children
      ),    // Stack / Scaffold body
    );
  }
}

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
        width: 200,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}

class _MenuCharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bodyPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 56, height: 50),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 56, height: 50),
      outlinePaint,
    );

    // Eyes
    for (final signX in [-1.0, 1.0]) {
      final eyeCenter = Offset(cx + signX * 10, cy - 4);
      canvas.drawCircle(eyeCenter, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
          eyeCenter + const Offset(1, 1), 4, Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
