import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game/antigravity_game.dart';
import 'game_screen.dart';
import 'skin_shop_screen.dart';
import 'achievement_screen.dart';
import 'mission_screen.dart';

class MenuScreen extends StatefulWidget {
  final AntiGravityGame game;
  const MenuScreen({super.key, required this.game});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;
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
          // Background
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
          Container(color: Colors.black.withValues(alpha: 0.38)),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
              children: [
                // Top bar: coin + icon buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ListenableBuilder(
                        listenable: widget.game.coinManager,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('💰',
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.game.coinManager.balance}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _IconMenuButton(
                            icon: '🏆',
                            label: '업적',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AchievementScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _IconMenuButton(
                            icon: '📋',
                            label: '미션',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MissionScreen(
                                  missionManager: widget.game.missionManager,
                                  coinManager: widget.game.coinManager,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Logo
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
                        width: 254,
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

                // Slogan
                const Text(
                  'Up Is Down',
                  style: TextStyle(
                    color: Color(0xFF82C8FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Color(0xFF4A90D9), blurRadius: 12),
                      Shadow(color: Color(0xFF82C8FF), blurRadius: 24),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // PLAY
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

                const SizedBox(height: 14),

                // Skin shop
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => SkinShopScreen(
                          coinManager: widget.game.coinManager,
                        ),
                      ),
                    );
                    widget.game.loadPrefs();
                  },
                  child: Container(
                    width: 220,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'SKIN SHOP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Best score
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
                        const Text('BEST ',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: Text(
                              '${widget.game.scoreManager.displayHighScore}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Character Preview (Bouncing)
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: child,
                    );
                  },
                  child: ListenableBuilder(
                    listenable: widget.game,
                    builder: (context, _) => _CharacterPreview(
                      skinRenderer: widget.game.skinRenderer,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Tilt toggle
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
                      const Text('Tilt Control',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 4),
                      Switch(
                        value: _tiltEnabled,
                        onChanged: (v) => setState(() => _tiltEnabled = v),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconMenuButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _IconMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
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
class _CharacterPreview extends StatefulWidget {
  final dynamic skinRenderer;
  const _CharacterPreview({required this.skinRenderer});

  @override
  State<_CharacterPreview> createState() => _CharacterPreviewState();
}

class _CharacterPreviewState extends State<_CharacterPreview>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastElapsed = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final elapsedSec = elapsed.inMicroseconds / 1000000.0;
      final dt = elapsedSec - _lastElapsed;
      _lastElapsed = elapsedSec;
      
      // Update internal constants of skinRenderer
      widget.skinRenderer.update(dt);
      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: _SkinPainter(widget.skinRenderer),
    );
  }
}

class _SkinPainter extends CustomPainter {
  final dynamic renderer;
  _SkinPainter(this.renderer);

  @override
  void paint(Canvas canvas, Size size) {
    renderer.draw(canvas, size.width / 2, size.height / 2, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
