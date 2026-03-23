import 'package:flutter/material.dart';
import '../game/antigravity_game.dart';
import '../game/game_state.dart';

class TutorialOverlay extends StatelessWidget {
  final AntiGravityGame game;
  const TutorialOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (_, __) {
        if (!game.isTutorialActive) return const SizedBox.shrink();

        final (icon, text) = _content(game.tutorialStep);

        return Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: _TutorialBubble(icon: icon, text: text),
        );
      },
    );
  }

  (IconData, String) _content(TutorialStep step) => switch (step) {
        TutorialStep.move => (Icons.screen_rotation_rounded, 'Tilt to move left & right'),
        TutorialStep.jump => (Icons.arrow_upward_rounded, 'Land on platforms to bounce up!'),
        TutorialStep.gravity =>
          (Icons.swap_vert_rounded, 'Tap anywhere → ANTI-GRAVITY! Float upward!'),
        TutorialStep.coin => (Icons.circle, 'Collect coins to unlock skins'),
        TutorialStep.done => (Icons.check, ''),
      };
}

class _TutorialBubble extends StatefulWidget {
  final IconData icon;
  final String text;
  const _TutorialBubble({required this.icon, required this.text});

  @override
  State<_TutorialBubble> createState() => _TutorialBubbleState();
}

class _TutorialBubbleState extends State<_TutorialBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -8)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.amber, size: 26),
              const SizedBox(width: 12),
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
