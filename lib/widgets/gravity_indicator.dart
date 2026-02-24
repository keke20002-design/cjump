import 'package:flutter/material.dart';
import '../game/antigravity_game.dart';

class GravityIndicator extends StatefulWidget {
  final AntiGravityGame game;
  const GravityIndicator({super.key, required this.game});

  @override
  State<GravityIndicator> createState() => _GravityIndicatorState();
}

class _GravityIndicatorState extends State<GravityIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 0,
    );
    widget.game.gravity.addFlipListener(_onFlip);
  }

  void _onFlip() {
    if (widget.game.gravity.isNormal) {
      _rotationCtrl.reverse();
    } else {
      _rotationCtrl.forward();
    }
  
  }

  @override
  void dispose() {
    widget.game.gravity.removeFlipListener(_onFlip);
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationCtrl, widget.game.gravity]),
      builder: (_, __) {
        final cooldownFraction = widget.game.gravity.cooldownFraction;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular cooldown progress + arrow
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cooldown ring
                  CircularProgressIndicator(
                    value: cooldownFraction,
                    strokeWidth: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(
                      widget.game.gravity.canFlip
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFFA726),
                    ),
                  ),
                  // Rotating arrow
                  Transform.rotate(
                    angle: _rotationCtrl.value * 3.14159,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFF4A90D9),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.game.gravity.isNormal ? 'NORMAL' : 'ANTI-G',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
              ),
            ),
          ],
        );
      },
    );
  }
}
