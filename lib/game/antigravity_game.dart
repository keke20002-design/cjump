import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';

import '../utils/constants.dart';
import '../utils/collision_detector.dart';
import 'game_state.dart';
import 'gravity_system.dart';
import 'score_manager.dart';
import 'combo_manager.dart';
import '../components/player.dart';
import '../components/platform.dart';
import '../components/background.dart';
import '../components/coin_component.dart';
import '../components/platform_types/normal_platform.dart';
import '../components/platform_types/moving_platform.dart';
import '../components/platform_types/breaking_platform.dart';
import '../components/platform_types/gravity_pad_platform.dart';
import '../components/platform_types/spike_platform.dart';
import '../components/platform_types/cloud_platform.dart';
import '../economy/coin_manager.dart';
import '../economy/persistence_manager.dart';
import '../achievements/achievement_manager.dart';
import '../missions/daily_mission_manager.dart';
import '../skins/skin_catalog.dart';
import '../skins/skin_renderer.dart';

class AntiGravityGame extends ChangeNotifier {
  // Core systems
  final GravitySystem gravity = GravitySystem();
  final ScoreManager scoreManager = ScoreManager();
  final CoinManager coinManager = CoinManager();
  final ComboManager comboManager = ComboManager();
  late final AchievementManager achievementManager;
  late final DailyMissionManager missionManager;

  // State
  GameState gameState = GameState.menu;

  // World
  late PlayerComponent player;
  final List<GamePlatform> platforms = [];
  final List<CoinComponent> coins = [];
  final BackgroundComponent background = BackgroundComponent();
  double cameraY = 0; // world Y of the top of visible area

  // Screen dimensions (set once on first frame)
  double screenWidth = 0;
  double screenHeight = 0;

  // Visual effects
  double _flashAlpha = 0;
  final List<_Particle> _particles = [];

  // Platform generation
  final Random _rng = Random();

  // Electric ceiling animation
  double _electricTimer = 0.0;

  // Accelerometer
  double _tiltX = 0;
  bool useTilt = true;

  // Audio
  final AudioPlayer _bouncePlayer = AudioPlayer();
  final AudioPlayer _flipPlayer = AudioPlayer();

  // Generation top tracking
  double _lowestGeneratedY = 0;
  double _highestGeneratedY = double.infinity;

  // Skin
  late SkinRenderer skinRenderer;
  int _lastScoreMilestone = 0;
  int _consecutiveLands = 0; // 연속 착지 카운터

  AntiGravityGame() {
    achievementManager = AchievementManager(coinManager: coinManager);
    missionManager = DailyMissionManager();
    gravity.addFlipListener(_onGravityFlip);
    _initSkin();
  }

  void _initSkin() {
    final catalog = buildSkinCatalog();
    final savedId = PersistenceManager.instance.selectedSkin;
    final skin = catalog.firstWhere(
      (s) => s.id == savedId,
      orElse: () => catalog.first,
    );
    skinRenderer = SkinRenderer(skin);
  }

  /// Called synchronously before startGame() — sets screen dimensions.
  void setScreenSize(double sw, double sh) {
    screenWidth = sw;
    screenHeight = sh;
    background.init(sw, sh);

    if (useTilt) {
      accelerometerEventStream().listen((event) {
        _tiltX = -event.x.clamp(-10.0, 10.0) / 10.0;
      });
    }
  }

  /// Loads persisted high score and all managers in the background.
  Future<void> loadPrefs() async {
    await scoreManager.init();
    await PersistenceManager.instance.init();
    await coinManager.init();
    await achievementManager.init();
    await missionManager.init();
    _initSkin(); // reload after prefs are loaded
    notifyListeners();
  }

  void startGame() {
    gravity.reset();
    scoreManager.reset();
    comboManager.reset();
    coinManager.resetSession();
    coinManager.clearDoubleCoins();
    achievementManager.resetSession();
    missionManager.resetSession();
    platforms.clear();
    coins.clear();
    _particles.clear();
    _flashAlpha = 0;
    _lastScoreMilestone = 0;
    _consecutiveLands = 0;

    final startX = screenWidth / 2;
    final startY = screenHeight * 0.6;

    player = PlayerComponent(x: startX, y: startY);
    player.reset(startX, startY);

    cameraY = startY - screenHeight * kCameraLead;

    // Generate initial platforms
    _lowestGeneratedY = startY + 40;
    _highestGeneratedY = startY - screenHeight * 3;
    _generatePlatformsDownward(startY + 40, startY + screenHeight);
    _generatePlatformsUpward(startY - 40, startY - screenHeight * 3);

    gameState = GameState.playing;
    notifyListeners();
  }

  void togglePause() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
    } else if (gameState == GameState.paused) {
      gameState = GameState.playing;
    }
    notifyListeners();
  }

  // ─── Game Loop ────────────────────────────────────────────────────────────

  void update(double dt) {
    if (gameState != GameState.playing) return;
    dt = dt.clamp(0, 0.05); // prevent spiral of death

    gravity.update(dt);
    background.update(dt, !gravity.isNormal); // crossfade play_g ↔ play_N
    skinRenderer.update(dt);

    // Horizontal from tilt or touch
    player.velocityX =
        _tiltX * kMaxHorizontalSpeed;

    player.update(dt, gravity, screenWidth);

    // 점수 업데이트 (콤보 배율 적용)
    final prevScore = scoreManager.displayScore;
    scoreManager.updateWithMultiplier(player.y, comboManager.multiplier);
    final newScore = scoreManager.displayScore;

    // 점수 100점마다 코인 보너스 + 업적 체크
    final milestone = newScore ~/ 100;
    if (milestone > _lastScoreMilestone) {
      _lastScoreMilestone = milestone;
      coinManager.onScoreMilestone();
    }
    if (newScore != prevScore) {
      achievementManager.onScoreUpdate(newScore);
      missionManager.onFlip; // score changes don't trigger flip
    }

    // Update platforms
    for (final p in platforms) {
      p.update(dt);
    }
    platforms.removeWhere((p) => p.isDestroyed);

    // Update coins
    for (final c in coins) {
      c.update(dt);
      // 마그넷 수집
      if (!c.isCollected) {
        final dx = player.x - c.x;
        final dy = player.y - c.y;
        if (dx * dx + dy * dy <= CoinComponent.magnetRange * CoinComponent.magnetRange) {
          c.collect();
          coinManager.onPlatformLand(); // +1 coin
          missionManager.onCoinCollected();
          achievementManager.onCoinsCollected(
              PersistenceManager.instance.statTotalCoinsEver + coinManager.sessionCoins);
        }
      }
    }
    coins.removeWhere((c) => c.isDead);

    // Collision detection
    _handleCollisions();

    // Camera: only follow player upward in NORMAL gravity.
    if (gravity.isNormal) {
      final targetCameraY = player.y - screenHeight * kCameraLead;
      if (targetCameraY < cameraY) {
        cameraY = targetCameraY;
      }
    }

    // Generate new platforms ahead of camera
    _generateAsNeeded();

    // Cull platforms behind camera
    _cullPlatforms();
    coins.removeWhere((c) {
      if (gravity.isNormal) return c.y > cameraY + screenHeight + 200;
      return c.y < cameraY - 200;
    });

    // Flash effect decay
    if (_flashAlpha > 0) {
      _flashAlpha -= dt * 4;
      _flashAlpha = _flashAlpha.clamp(0, 1);
    }

    // Electric ceiling timer
    _electricTimer += dt;

    // Update particles
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);

    // Game over check
    _checkGameOver();

    // Ceiling death: antigravity player touches the electric wire (screen-space check)
    if (!gravity.isNormal) {
      final playerScreenY = player.y - cameraY;
      if (playerScreenY - kCharacterSize / 2 <= kElectricWireY) {
        _triggerGameOver();
      }
    }
  }

  void _handleCollisions() {
    for (final platform in platforms) {
      if (platform.isDestroyed) continue;

      // Cloud: only solid in normal gravity
      if (platform is CloudPlatform && !gravity.isNormal) continue;

      final collision = CollisionDetector.check(
        charRect: player.bounds,
        platformRect: platform.bounds,
        velocityY: player.velocityY,
        isNormalGravity: gravity.isNormal,
      );

      if (collision == null) continue;

      // Spike = game over
      if (platform.type == PlatformType.spike) {
        _triggerGameOver();
        return;
      }

      final shouldBounce = platform.onPlayerBounce();
      if (shouldBounce) {
        player.velocityY = gravity.isNormal ? -kJumpVelocity : kJumpVelocity;
        player.onBounce();
        _playBounce();

        // ── 착지 이벤트 훅 ────────────────────────────────────────────────
        _consecutiveLands++;
        final isGravPad = platform.type == PlatformType.gravityPad;
        coinManager.onPlatformLand(isGravityPad: isGravPad);
        comboManager.onLand();
        missionManager.onConsecutivePlatform(_consecutiveLands);
        achievementManager.onPlatformLand(_consecutiveLands);
        achievementManager.onComboReached(comboManager.combo);
        missionManager.onCombo(comboManager.combo);

        // 코인 아이템 스폰 (최대 8개)
        if (coins.length < 8 && _rng.nextDouble() < 0.35) {
          coins.add(CoinComponent(
            x: platform.x + (_rng.nextDouble() - 0.5) * 40,
            y: platform.y - 20,
          ));
        }
      }
    }
  }

  void _checkGameOver() {
    // Game over: player goes off the "dangerous" edge
    if (gravity.isNormal) {
      // Falls below screen bottom
      if (player.y > cameraY + screenHeight + kCharacterSize * 2) {
        _triggerGameOver();
      }
    } else {
      // Antigravity: falls above screen top
      if (player.y < cameraY - kCharacterSize * 2) {
        _triggerGameOver();
      }
    }
  }

  void _triggerGameOver() {
    gameState = GameState.gameOver;
    comboManager.onBreak();
    scoreManager.saveHighScore();
    final finalScore = scoreManager.displayScore;
    // 비동기 세션 커밋
    coinManager.commitSession().then((_) {
      comboManager.commitSession();
      achievementManager.onGameOver(finalScore);
      missionManager.onGameOver(finalScore);
      // 점수 기반 스킨 자동 해금 체크
      checkScoreUnlocks(scoreManager.displayHighScore);
    });
    notifyListeners();
  }

  // ─── Platform Generation ──────────────────────────────────────────────────

  void _generateAsNeeded() {
    // score used in _generateAsNeeded → _spawnPlatformAt
    final genBottom = cameraY + screenHeight * 2;
    final genTop = cameraY - screenHeight * 2;

    if (_lowestGeneratedY < genBottom) {
      _generatePlatformsDownward(_lowestGeneratedY, genBottom);
    }
    if (_highestGeneratedY > genTop) {
      _generatePlatformsUpward(_highestGeneratedY, genTop);
    }
  }

  void _generatePlatformsDownward(double fromY, double toY) {
    double y = fromY;
    while (y < toY) {
      final gap = _rng.nextDouble() * (kMaxPlatformGap - kMinPlatformGap) + kMinPlatformGap;
      y += gap;
      _spawnPlatformAt(y);
    }
    _lowestGeneratedY = y;
  }

  void _generatePlatformsUpward(double fromY, double toY) {
    double y = fromY;
    while (y > toY) {
      final gap = _rng.nextDouble() * (kMaxPlatformGap - kMinPlatformGap) + kMinPlatformGap;
      y -= gap;
      _spawnPlatformAt(y);
    }
    _highestGeneratedY = y;
  }

  void _spawnPlatformAt(double worldY) {
    final score = scoreManager.displayScore;
    final x = _rng.nextDouble() * (screenWidth - kPlatformWidth) + kPlatformWidth / 2;
    final p = _pickPlatformType(score, x, worldY);
    platforms.add(p);
  }

  GamePlatform _pickPlatformType(int score, double x, double y) {
    final roll = _rng.nextDouble();
    if (score < 500) {
      // 80% normal, 20% moving
      if (roll < 0.80) return NormalPlatform(x: x, y: y);
      return MovingPlatform(x: x, y: y, screenWidth: screenWidth);
    } else if (score < 1500) {
      // 60% normal, 20% moving, 10% breaking, 10% gravity pad
      if (roll < 0.60) return NormalPlatform(x: x, y: y);
      if (roll < 0.80) return MovingPlatform(x: x, y: y, screenWidth: screenWidth);
      if (roll < 0.90) return BreakingPlatform(x: x, y: y);
      return GravityPadPlatform(x: x, y: y, gravitySystem: gravity);
    } else {
      // 40% normal, 20% moving, 15% breaking, 15% gravity pad, 10% spike
      if (roll < 0.40) return NormalPlatform(x: x, y: y);
      if (roll < 0.60) return MovingPlatform(x: x, y: y, screenWidth: screenWidth);
      if (roll < 0.75) return BreakingPlatform(x: x, y: y);
      if (roll < 0.90) return GravityPadPlatform(x: x, y: y, gravitySystem: gravity);
      return SpikePlatform(x: x, y: y);
    }
  }

  void _cullPlatforms() {
    final cullThreshold = screenHeight * 2;
    platforms.removeWhere((p) {
      if (gravity.isNormal) {
        return p.y > cameraY + screenHeight + cullThreshold;
      } else {
        return p.y < cameraY - cullThreshold;
      }
    });
  }

  // ─── Input ────────────────────────────────────────────────────────────────

  void onTap() {
    if (gameState != GameState.playing) return;
    final flipped = gravity.tryFlip();
    if (flipped) {
      _playFlip();
      HapticFeedback.mediumImpact();
    }
  }

  void setTiltX(double value) {
    if (!useTilt) _tiltX = value;
  }

  void setLeftPressed(bool pressed) {
    if (!useTilt) _tiltX = pressed ? -1.0 : 0.0;
  }

  void setRightPressed(bool pressed) {
    if (!useTilt) _tiltX = pressed ? 1.0 : 0.0;
  }

  // ─── Gravity Flip Effects ─────────────────────────────────────────────────

  void _onGravityFlip() {
    _flashAlpha = 0.35;
    _spawnFlipParticles();
    _consecutiveLands = 0; // 착지 연속 초기화
    comboManager.onBreak();  // 콤보 리셋은 선택사항 - 중력뒤집기는 스킬이므로 유지
    achievementManager.onGravityFlip();
    missionManager.onFlip();
  }

  void _spawnFlipParticles() {
    for (int i = 0; i < 20; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 200 + 50;
      _particles.add(_Particle(
        x: player.x,
        y: player.y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: gravity.isNormal
            ? const Color(0xFF42A5F5)
            : const Color(0xFFAB47BC),
      ));
    }
  }

  // ─── Rendering ────────────────────────────────────────────────────────────

  void render(Canvas canvas, Size size) {
    // Draw background (world-space aware)
    background.draw(canvas, size, cameraY);

    // Transform canvas to world space
    canvas.save();
    canvas.translate(0, -cameraY);

    // Draw platforms
    for (final p in platforms) {
      if (p.y < cameraY - 60 || p.y > cameraY + size.height + 60) continue;
      p.draw(canvas);
    }

    // Draw coins
    for (final c in coins) {
      c.draw(canvas);
    }

    // Draw player (with skin)
    skinRenderer.draw(canvas, player.x, player.y, gravity.isNormal);

    // Draw particles
    for (final p in _particles) {
      p.draw(canvas);
    }

    canvas.restore();

    // ── Electric ceiling barrier (antigravity death zone) ──
    if (!gravity.isNormal) {
      _drawElectricCeiling(canvas, size);
    }

    // Screen flash on gravity flip
    if (_flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = (gravity.isNormal
                  ? const Color(0xFF42A5F5)
                  : const Color(0xFFAB47BC))
              .withValues(alpha: _flashAlpha),
      );
    }
  }

  void _drawElectricCeiling(Canvas canvas, Size size) {
    const barrierH = kElectricWireY;
    final w = size.width;

    // Glowing background strip
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF1744).withValues(alpha: 0.85),
          const Color(0xFFFF6D00).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, barrierH * 4));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, barrierH * 4), bgPaint);

    // Main wire line
    final wirePaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, barrierH), Offset(w, barrierH), wirePaint);

    // Glow around wire
    final glowPaint = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.35)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(Offset(0, barrierH), Offset(w, barrierH), glowPaint);

    // Animated lightning bolts
    final boltPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final boltGlow = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Use seeded random driven by timer for flicker
    final seed = (_electricTimer * 8).floor();
    final rng = Random(seed);
    final boltCount = 5 + rng.nextInt(4);
    for (int i = 0; i < boltCount; i++) {
      final bx = rng.nextDouble() * w;
      final segments = 3 + rng.nextInt(3);
      double cy = barrierH;
      double cx = bx;
      final path = Path()..moveTo(cx, cy);
      for (int s = 0; s < segments; s++) {
        cx += (rng.nextDouble() - 0.5) * 12;
        cy += rng.nextDouble() * 10 + 4;
        path.lineTo(cx, cy);
      }
      canvas.drawPath(path, boltGlow);
      canvas.drawPath(path, boltPaint);
    }

    // "DANGER" insulator caps
    final capPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;
    for (double x = 20; x < w; x += w / 6) {
      canvas.drawCircle(Offset(x, barrierH), 5, capPaint);
      canvas.drawCircle(
        Offset(x, barrierH),
        5,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  // ─── Audio ────────────────────────────────────────────────────────────────

  void _playBounce() {
    // Audio files are optional - silently fail if missing
    // _bouncePlayer.play(AssetSource('audio/bounce.mp3'));
  }

  void _playFlip() {
    // _flipPlayer.play(AssetSource('audio/flip.mp3'));
  }

  @override
  void dispose() {
    _bouncePlayer.dispose();
    _flipPlayer.dispose();
    super.dispose();
  }
}

// ─── Particle ───────────────────────────────────────────────────────────────

class _Particle {
  double x, y, vx, vy;
  final Color color;
  double life = 1.0;
  static const double _decay = 2.0;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
  });

  bool get isDead => life <= 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 200 * dt; // gravity on particles
    life -= _decay * dt;
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color.withValues(alpha: life.clamp(0, 1))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 4 * life.clamp(0, 1), paint);
  }
}
