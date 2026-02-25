import 'package:flutter/material.dart';
import '../achievements/achievement_model.dart';

/// 업적 달성 시 화면 상단에서 슬라이드 다운되는 알림 위젯
class AchievementPopup extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismissed;

  const AchievementPopup({
    super.key,
    required this.achievement,
    required this.onDismissed,
  });

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();

    // 2.5초 후 자동 슬라이드 업
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 이모지 아이콘
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(a.iconEmoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🏆 업적 달성!',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (a.rewardCoins > 0 || a.rewardSkinId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              a.rewardSkinId != null
                                  ? '스킨 해금 + ${a.rewardCoins}코인 획득!'
                                  : '+${a.rewardCoins}코인 획득!',
                              style: const TextStyle(
                                color: Color(0xFF69FF47),
                                fontSize: 11,
                              ),
                            ),
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
    );
  }
}

/// 업적 팝업 큐를 관리하는 오버레이
class AchievementPopupQueue extends StatefulWidget {
  final Widget child;
  final List<Achievement> Function() getPending;
  final Achievement? Function() popPopup;

  const AchievementPopupQueue({
    super.key,
    required this.child,
    required this.getPending,
    required this.popPopup,
  });

  @override
  State<AchievementPopupQueue> createState() => _AchievementPopupQueueState();
}

class _AchievementPopupQueueState extends State<AchievementPopupQueue> {
  Achievement? _current;
  bool _showing = false;

  void _tryShowNext() {
    if (_showing) return;
    final next = widget.popPopup();
    if (next == null) return;
    setState(() {
      _current = next;
      _showing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showing && _current != null)
          AchievementPopup(
            achievement: _current!,
            onDismissed: () {
              setState(() {
                _showing = false;
                _current = null;
              });
              Future.delayed(const Duration(milliseconds: 200), _tryShowNext);
            },
          ),
      ],
    );
  }
}
