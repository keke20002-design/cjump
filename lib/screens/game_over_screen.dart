import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../game/antigravity_game.dart';
import '../ads/ad_manager.dart';
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
  late final Animation<double> _coinFadeAnim;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;
  bool _hasRevived = false; // only one revive per game over
  bool _adButtonReady = false;

  int get _finalScore => widget.game.scoreManager.displayScore;
  int get _highScore => widget.game.scoreManager.displayHighScore;
  bool get _isNewHighScore => _finalScore >= _highScore && _finalScore > 0;

  String get _scoreMessage {
    if (_finalScore < 20) return 'Keep Trying';
    if (_finalScore < 100) return 'Not Bad!';
    if (_finalScore < 200) return 'Great!';
    return 'Amazing!!';
  }

  Color get _messageColor {
    if (_finalScore < 20) return Colors.white54;
    if (_finalScore < 100) return const Color(0xFF80CBC4);
    if (_finalScore < 200) return const Color(0xFF81C784);
    return Colors.amber;
  }

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
    // Coin popup fades in during the second half of the count animation
    _coinFadeAnim = CurvedAnimation(
      parent: _countCtrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _countCtrl.forward();
    });

    // Banner ad
    if (!kIsWeb) {
      _bannerAd = AdManager.instance.createBanner(
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _bannerLoaded = true);
          },
        ),
      );
    }

    // Rewarded ad readiness check - 이미 부활했으면 버튼 숨김
    setState(() => _adButtonReady =
        AdManager.instance.isRewardedReady && !widget.game.hasUsedRevive);
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinsEarned = widget.game.coinManager.sessionCoins;
    final gap = _highScore - _finalScore;

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
                    Color(0xFF0D1B2A),
                  ],
                ),
              ),
            ),
          ),

          // ── Dark overlay ──
          Container(color: Colors.black.withValues(alpha: 0.60)),

          // ── Content ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
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

                          // ── Score-based message ──
                          const SizedBox(height: 8),
                          Text(
                            _scoreMessage,
                            style: TextStyle(
                              color: _messageColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),

                          const SizedBox(height: 28),

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

                                // ── NEW HIGH SCORE badge ──
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
                                        Icon(Icons.star, color: Colors.amber, size: 14),
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
                                        Icon(Icons.star, color: Colors.amber, size: 14),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                const Divider(color: Colors.white12, height: 8),
                                const SizedBox(height: 8),

                                // ── +X COINS slide-up popup ──
                                FadeTransition(
                                  opacity: _coinFadeAnim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.6),
                                      end: Offset.zero,
                                    ).animate(_coinFadeAnim),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.circle,
                                            color: Colors.amber, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          '+$coinsEarned COINS',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                const Divider(color: Colors.white12, height: 8),
                                const SizedBox(height: 8),

                                // ── BEST row ──
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

                                // ── Gap hint ──
                                if (!_isNewHighScore && gap > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    gap <= 20 ? 'SO CLOSE!' : '$gap away from best',
                                    style: TextStyle(
                                      color: gap <= 20
                                          ? const Color(0xFFFF7043)
                                          : Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── [WEB TEST] Watch Ad Resume button — disabled ──
                          if (false && kIsWeb && !_hasRevived) ...[
                            GestureDetector(
                              onTap: () {
                                setState(() => _hasRevived = true);
                                widget.game.revive();
                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GameScreen(game: widget.game),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 220,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6A1B9A),
                                      Color(0xFFAB47BC),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6A1B9A)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bug_report,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'TEST: AD RESUME',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── WATCH AD → CONTINUE ──
                          if (_adButtonReady && !_hasRevived) ...[
                            GestureDetector(
                              onTap: () {
                                setState(() => _adButtonReady = false);
                                AdManager.instance.showRewarded(
                                  onRewarded: () {
                                    _hasRevived = true;
                                    widget.game.revive();
                                    if (mounted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              GameScreen(game: widget.game),
                                        ),
                                      );
                                    }
                                  },
                                  onDone: () {
                                    if (mounted) {
                                      setState(() => _adButtonReady =
                                          AdManager.instance.isRewardedReady);
                                    }
                                  },
                                );
                              },
                              child: Container(
                                width: 220,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6D00),
                                      Color(0xFFFFAB40),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6D00)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle_fill,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'WATCH AD → CONTINUE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── PLAY AGAIN — pulsing button ──
                          _PulseButton(
                            label: 'PLAY AGAIN',
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              AdManager.instance.showInterstitialIfReady(
                                onDone: () {
                                  widget.game.startGame();
                                  if (mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            GameScreen(game: widget.game),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // ── Tap to retry hint ──
                          const Text(
                            'Tap to retry',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── MENU ──
                          TextButton(
                            onPressed: () {
                              AdManager.instance.showInterstitialIfReady(
                                onDone: () {
                                  if (mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MenuScreen(game: widget.game),
                                      ),
                                      (_) => false,
                                    );
                                  }
                                },
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

                          // ── Banner Ad ──
                          if (_bannerLoaded && _bannerAd != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: _bannerAd!.size.width.toDouble(),
                              height: _bannerAd!.size.height.toDouble(),
                              child: AdWidget(ad: _bannerAd!),
                            ),
                          ],
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────

class _PulseButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PulseButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 220,
          height: 56,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
