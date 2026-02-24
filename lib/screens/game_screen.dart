import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game/antigravity_game.dart';
import '../game/game_state.dart';
import '../widgets/hud_overlay.dart';
import 'game_over_screen.dart';
import 'menu_screen.dart';

class GameScreen extends StatefulWidget {
  final AntiGravityGame game;
  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastTime = Duration.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    widget.game.addListener(_onGameStateChanged);
  }

  void _tick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    final dt = (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;
    widget.game.update(dt);
    if (mounted) setState(() {});
  }

  void _onGameStateChanged() {
    if (widget.game.gameState == GameState.gameOver && mounted) {
      _ticker.stop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameOverScreen(game: widget.game),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final size = MediaQuery.of(context).size;
      widget.game.setScreenSize(size.width, size.height);
      // Defer until after first frame so notifyListeners() doesn't fire during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.game.startGame();
        widget.game.loadPrefs();
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.game.removeListener(_onGameStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: widget.game.onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Game canvas
            CustomPaint(
              painter: _GamePainter(game: widget.game),
              child: const SizedBox.expand(),
            ),

            // HUD
            HudOverlay(game: widget.game),

            // Tilt-off: left/right buttons
            if (!widget.game.useTilt)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DirectionButton(
                      icon: Icons.arrow_left_rounded,
                      onPressStart: () =>
                          widget.game.setLeftPressed(true),
                      onPressEnd: () =>
                          widget.game.setLeftPressed(false),
                    ),
                    // Gravity flip button in center
                    GestureDetector(
                      onTap: widget.game.onTap,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90D9).withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4A90D9).withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert,
                            color: Colors.white, size: 30),
                      ),
                    ),
                    _DirectionButton(
                      icon: Icons.arrow_right_rounded,
                      onPressStart: () =>
                          widget.game.setRightPressed(true),
                      onPressEnd: () =>
                          widget.game.setRightPressed(false),
                    ),
                  ],
                ),
              ),

            // Home button (top-left, always visible during play)
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: IconButton(
                  tooltip: '홈으로',
                  icon: const Icon(Icons.home_rounded, color: Colors.white70),
                  onPressed: () async {
                    widget.game.togglePause();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('홈으로 나가기',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        content: const Text(
                          '현재 게임이 종료됩니다.\n정말 나가시겠어요?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('취소',
                                style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90D9),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('나가기',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (!context.mounted) return;
                    if (confirmed == true) {
                      Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(game: widget.game),
                      ),
                    );
                    } else if (confirmed == false) {
                      if (widget.game.gameState == GameState.paused) {
                        widget.game.togglePause();
                      }
                    }
                  },
                ),
              ),
            ),

            // Pause button (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  tooltip: widget.game.gameState == GameState.paused
                      ? '계속하기'
                      : '일시정지',
                  icon: Icon(
                    widget.game.gameState == GameState.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white70,
                    size: 28,
                  ),
                  onPressed: widget.game.togglePause,
                ),
              ),
            ),

            // Pause overlay
            if (widget.game.gameState == GameState.paused)
              _PauseOverlay(
                onResume: widget.game.togglePause,
                onRestart: () {
                  widget.game.startGame();
                },
                onHome: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('홈으로 나가기',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      content: const Text(
                        '현재 게임이 종료됩니다.\n정말 나가시겠어요?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('취소',
                              style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90D9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('나가기',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  if (confirmed == true) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(game: widget.game),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final AntiGravityGame game;
  _GamePainter({required this.game});

  @override
  void paint(Canvas canvas, Size size) {
    game.render(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}

// ─── Pause Overlay ────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4A90D9).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.pause_rounded,
                    color: Color(0xFF4A90D9), size: 30),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 28),
              // Resume button
              _PauseMenuButton(
                icon: Icons.play_arrow_rounded,
                label: '계속하기',
                color: const Color(0xFF4CAF50),
                onTap: onResume,
              ),
              const SizedBox(height: 12),
              // Restart button
              _PauseMenuButton(
                icon: Icons.replay_rounded,
                label: '다시 시작',
                color: const Color(0xFF4A90D9),
                onTap: onRestart,
              ),
              const SizedBox(height: 12),
              // Home button
              _PauseMenuButton(
                icon: Icons.home_rounded,
                label: '홈으로',
                color: const Color(0xFFAB47BC),
                onTap: onHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PauseMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Direction Button ─────────────────────────────────────────────────────────

class _DirectionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  const _DirectionButton({
    required this.icon,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: onPressEnd,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Icon(icon, color: Colors.white70, size: 40),
      ),
    );
  }
}
