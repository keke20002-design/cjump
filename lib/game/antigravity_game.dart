import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
import '../components/platform_types/booster_platform.dart';
import '../components/magnet_item.dart';
import '../components/shield_item.dart';
import '../components/meteor.dart';
import '../components/laser_trap.dart';
import '../components/black_hole.dart';
import '../components/junk_bot.dart';
import '../components/platform_types/crystal_platform.dart';
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
  final List<MagnetItem> magnets = [];
  final BackgroundComponent background = BackgroundComponent();

  // Magnet
  double _magnetTimer = 0;

  // Shield
  final List<ShieldItem> _shieldItems = [];
  double _shieldTimer = 0;
  bool get isShielded => _shieldTimer > 0;
  double get shieldFraction => (_shieldTimer / ShieldItem.shieldDuration).clamp(0, 1);

  // Hazard spawn delay (after revive)
  double _hazardDelay = 0;
  bool get magnetActive => _magnetTimer > 0;
  double get magnetFraction => (_magnetTimer / MagnetItem.magnetDuration).clamp(0, 1);

  // Meteors
  final List<Meteor> _meteors = [];
  double _meteorSpawnTimer = 0;

  // Laser traps
  final List<LaserTrap> _lasers = [];

  // Black holes
  final List<BlackHole> _blackHoles = [];
  double _blackHoleSpawnTimer = 0;

  // Junk bots
  final List<JunkBot> _junkBots = [];
  double _junkBotSpawnTimer = 0;

  // Coin Rain
  bool _coinRainActive = false;
  double _coinRainTimer = 0;
  double _coinRainSpawnTimer = 0;
  bool get coinRainActive => _coinRainActive;
  double cameraY = 0; // world Y of the top of visible area
  double _scrollSpeed = kBaseScrollSpeed;

  // Screen dimensions (set once on first frame)
  double screenWidth = 0;
  double screenHeight = 0;

  // Visual effects
  double _flashAlpha = 0;
  Color _flashColor = const Color(0xFF42A5F5);
  double _shakeTimer = 0;
  double _dyingTimer = 0;
  final List<_Particle> _particles = [];

  // Antigravity ghost trail
  final List<Offset> _ghostTrail = [];
  double _ghostSampleTimer = 0;

  // Bonus chance (one per game — safety net when player falls off bottom)
  bool _bonusChanceUsed = false;
  bool _bonusChanceActive = false;
  double _bonusChanceTimer = 0;
  bool get bonusChanceActive => _bonusChanceActive;

  // Platform generation
  final Random _rng = Random();

  // Electric ceiling animation
  double _electricTimer = 0.0;

  // Accelerometer
  double _tiltX = 0;
  bool useTilt = !kIsWeb; // web uses on-screen buttons

  // Audio
  final AudioPlayer _bouncePlayer = AudioPlayer();
  final AudioPlayer _flipPlayer = AudioPlayer();
  final AudioPlayer _gameOverPlayer = AudioPlayer();
  final AudioPlayer _boosterPlayer = AudioPlayer();

  // Generation top tracking
  double _lowestGeneratedY = 0;
  double _highestGeneratedY = double.infinity;

  // Skin
  late SkinRenderer skinRenderer;
  int _lastScoreMilestone = 0;
  int _consecutiveLands = 0; // 연속 착지 카운터

  // Tutorial
  TutorialStep _tutorialStep = TutorialStep.done;
  Timer? _tutorialTimer;
  bool get isTutorialActive => _tutorialStep != TutorialStep.done;
  TutorialStep get tutorialStep => _tutorialStep;

  // Revive tracking (one revive per game session)
  bool hasUsedRevive = false;

  // Meteor warnings (! indicator before spawn)
  final List<_MeteorWarning> _meteorWarnings = [];

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
    if (PersistenceManager.instance.isFirstRun) {
      _tutorialStep = TutorialStep.move;
      _startTutorialWithTimeout();
    }
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
    magnets.clear();
    _meteors.clear();
    _meteorSpawnTimer = 0;
    _lasers.clear();
    _blackHoles.clear();
    _blackHoleSpawnTimer = 0;
    _junkBots.clear();
    _junkBotSpawnTimer = 0;
    _shieldItems.clear();
    _shieldTimer = 0;
    _hazardDelay = 0;
    _particles.clear();
    _flashColor = const Color(0xFF42A5F5);
    _dyingTimer = 0;
    _magnetTimer = 0;
    _coinRainActive = false;
    _coinRainTimer = 0;
    _coinRainSpawnTimer = 0;
    _flashAlpha = 0;
    _lastScoreMilestone = 0;
    _consecutiveLands = 0;
    _bonusChanceUsed = false;
    _bonusChanceActive = false;
    _bonusChanceTimer = 0;
    _scrollSpeed = kBaseScrollSpeed;
    hasUsedRevive = false;
    _meteorWarnings.clear();
    if (PersistenceManager.instance.isFirstRun) {
      _tutorialStep = TutorialStep.move;
      _startTutorialWithTimeout();
    }

    final startX = screenWidth / 2;
    final startY = screenHeight * 0.6;

    player = PlayerComponent(x: startX, y: startY);
    player.reset(startX, startY);

    cameraY = startY - screenHeight * kCameraLead;

    // 시작 플랫폼: 캐릭터 바로 아래에 보장 + 코인/자석도 함께 스폰
    final startPlatY = startY + kCharacterSize * 0.8;
    void addStartPlatform(double x, double y) {
      final p = NormalPlatform(x: x, y: y);
      platforms.add(p);
      _spawnCoinsForPlatform(p, allowMagnet: false);
    }
    addStartPlatform(startX, startPlatY);
    addStartPlatform(startX - 60, startPlatY + 100);
    addStartPlatform(startX + 60, startPlatY + 200);

    // Generate initial platforms
    _lowestGeneratedY = startPlatY + 220;
    _highestGeneratedY = startY - screenHeight * 3;
    _generatePlatformsDownward(_lowestGeneratedY, startY + screenHeight);
    _generatePlatformsUpward(startY - 40, startY - screenHeight * 3);

    gameState = GameState.playing;
    notifyListeners();
  }

  void togglePause() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
    } else if (gameState == GameState.paused) {
      gameState = GameState.playing;
    } else {
      return; // No pause during dying/gameOver/menu
    }
    notifyListeners();
  }

  // ─── Game Loop ────────────────────────────────────────────────────────────

  void update(double dt) {
    dt = dt.clamp(0, 0.05); // prevent spiral of death

    // Dying state: freeze player, play particles/effects, then finalize
    if (gameState == GameState.dying) {
      _dyingTimer -= dt;
      // Decay flash faster during dying
      if (_flashAlpha > 0) {
        _flashAlpha -= dt * 2.5;
        _flashAlpha = _flashAlpha.clamp(0, 1);
      }
      if (_shakeTimer > 0) _shakeTimer -= dt;
      for (final p in _particles) {
        p.update(dt);
      }
      _particles.removeWhere((p) => p.isDead);
      if (_dyingTimer <= 0) _finalizeGameOver();
      return;
    }

    if (gameState != GameState.playing) return;

    _scrollSpeed += 0.002 * (60 * dt); // ~0.002 per frame increase
    cameraY -= _scrollSpeed * dt; // Auto-scroll camera upward

    gravity.update(dt, scoreManager.displayScore);
    background.update(dt, !gravity.isNormal); // crossfade play_g ↔ play_N
    skinRenderer.update(dt);

    // Horizontal from tilt or touch
    player.velocityX = _tiltX * kMaxHorizontalSpeed;

    if (_tutorialStep == TutorialStep.move && _tiltX.abs() > 0.1) {
      _advanceTutorial(TutorialStep.move);
    }

    player.update(dt, gravity, screenWidth);

    // Ghost trail: sample position every ~40ms in antigravity, clear when normal
    if (!gravity.isNormal) {
      _ghostSampleTimer += dt;
      if (_ghostSampleTimer >= 0.04) {
        _ghostSampleTimer = 0;
        _ghostTrail.add(Offset(player.x, player.y));
        if (_ghostTrail.length > 8) _ghostTrail.removeAt(0);
      }
    } else {
      _ghostTrail.clear();
      _ghostSampleTimer = 0;
    };

    // 점수 업데이트 (콤보 배율 적용)
    final prevScore = scoreManager.displayScore;
    scoreManager.updateWithMultiplier(player.y, comboManager.multiplier);
    final newScore = scoreManager.displayScore;

    // 점수 100점마다 업적 체크 + 코인 비 발동 확률
    final milestone = newScore ~/ 100;
    if (milestone > _lastScoreMilestone) {
      _lastScoreMilestone = milestone;
      if (newScore > 120 && !_coinRainActive && _rng.nextDouble() < 0.02) {
        _coinRainActive = true;
        _coinRainTimer = 5.0;
        _coinRainSpawnTimer = 0;
        notifyListeners();
      }
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

    // Magnet timer
    if (_magnetTimer > 0) {
      _magnetTimer = (_magnetTimer - dt).clamp(0, MagnetItem.magnetDuration);
    }

    // Shield timer
    if (_shieldTimer > 0) {
      _shieldTimer = (_shieldTimer - dt).clamp(0, ShieldItem.shieldDuration);
      if (_shieldTimer == 0) notifyListeners();
    }

    // Hazard spawn delay after revive
    if (_hazardDelay > 0) {
      _hazardDelay -= dt;
    }

    // Coin Rain
    if (_coinRainActive) {
      _coinRainTimer -= dt;
      _coinRainSpawnTimer -= dt;
      if (_coinRainSpawnTimer <= 0) {
        _coinRainSpawnTimer = 0.2;
        coins.add(CoinComponent(
          x: _rng.nextDouble() * screenWidth,
          y: cameraY + 10,
          vy: 180,
        ));
      }
      if (_coinRainTimer <= 0) {
        _coinRainActive = false;
        notifyListeners();
      }
    }

    // Meteor spawn + update
    _updateMeteors(dt);

    // Laser traps
    _updateLasers(dt);

    // Black holes and junk bots
    _updateBlackHoles(dt);
    _updateJunkBots(dt);

    // Update coins + magnet attraction
    for (final c in coins) {
      c.update(dt);
      if (!c.isCollected) {
        // 자석 흡착
        if (magnetActive) {
          final dx = player.x - c.x;
          final dy = player.y - c.y;
          final distSq = dx * dx + dy * dy;
          const magnetRadius = 120.0;
          if (distSq < magnetRadius * magnetRadius) {
            final dist = sqrt(distSq);
            const speed = 450.0;
            c.x += dx / dist * speed * dt;
            c.y += dy / dist * speed * dt;
          }
        }

        // 수집 판정
        final dx = player.x - c.x;
        final dy = player.y - c.y;
        final collectRange = magnetActive ? 24.0 : CoinComponent.magnetRange;
        if (dx * dx + dy * dy <= collectRange * collectRange) {
          c.collect();
          coinManager.onCoinItemCollected(c.value);
          missionManager.onCoinCollected();
          achievementManager.onCoinsCollected(
              PersistenceManager.instance.statTotalCoinsEver + coinManager.sessionCoins);
          _advanceTutorial(TutorialStep.coin);
        }
      }
    }
    coins.removeWhere((c) => c.isDead);

    // Update magnets
    for (final m in magnets) {
      m.update(dt);
      if (!m.collected) {
        final dx = player.x - m.x;
        final dy = player.y - m.y;
        if (dx * dx + dy * dy <= MagnetItem.collectRange * MagnetItem.collectRange) {
          m.collected = true;
          _magnetTimer = MagnetItem.magnetDuration;
          notifyListeners();
        }
      }
    }
    magnets.removeWhere((m) => m.isDead);

    // Shield item collection
    for (final s in _shieldItems) {
      s.update(dt);
      if (!s.collected) {
        final dx = player.x - s.x;
        final dy = player.y - s.y;
        if (dx * dx + dy * dy <= ShieldItem.collectRange * ShieldItem.collectRange) {
          s.collected = true;
          _shieldTimer = ShieldItem.shieldDuration;
          notifyListeners();
        }
      }
    }
    _shieldItems.removeWhere((s) => s.isDead);
    _shieldItems.removeWhere((s) {
      if (gravity.isNormal) return s.y > cameraY + screenHeight * 3;
      return s.y < cameraY - screenHeight * 3;
    });

    // Collision detection
    _handleCollisions(dt);

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
      if (gravity.isNormal) return c.y > cameraY + screenHeight * 3;
      return c.y < cameraY - screenHeight * 3;
    });
    magnets.removeWhere((m) {
      if (gravity.isNormal) return m.y > cameraY + screenHeight * 3;
      return m.y < cameraY - screenHeight * 3;
    });
    _lasers.removeWhere((l) {
      if (gravity.isNormal) return l.y > cameraY + screenHeight * 3;
      return l.y < cameraY - screenHeight * 3;
    });

    // Flash effect decay
    if (_flashAlpha > 0) {
      _flashAlpha -= dt * 4;
      _flashAlpha = _flashAlpha.clamp(0, 1);
    }

    // Shake effect decay
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
    }

    // Electric ceiling timer
    _electricTimer += dt;

    // Bonus chance banner timer
    if (_bonusChanceTimer > 0) {
      _bonusChanceTimer -= dt;
      if (_bonusChanceTimer <= 0) {
        _bonusChanceActive = false;
      }
    }

    // Update particles
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.isDead);

    // Game over check
    if (player.y <= kWorldTopLimit) {
      _triggerGameOver();
    }
    _checkGameOver();

    // Ceiling death: antigravity player touches the electric wire (screen-space check)
    if (!gravity.isNormal) {
      final playerScreenY = player.y - cameraY;
      if (playerScreenY - kCharacterSize / 2 <= kElectricWireY) {
        _triggerGameOver();
      }
    }
  }

  void _handleCollisions(double dt) {
    for (final platform in platforms) {
      if (platform.isDestroyed) continue;

      // During gravity flip transition, determine collision surface from velocity
      // direction instead of gravity state — prevents tunnel-through when velocity
      // hasn't yet reversed to match the new gravity direction.
      final isNormalForCollision = gravity.isTransitioning
          ? player.velocityY > 0
          : gravity.isNormal;

      // Cloud: only solid when treating collision as normal gravity
      if (platform is CloudPlatform && !isNormalForCollision) continue;

      final collision = CollisionDetector.check(
        charRect: player.bounds,
        platformRect: platform.bounds,
        velocityY: player.velocityY,
        isNormalGravity: isNormalForCollision,
        dt: dt,
      );

      if (collision == null) continue;

      // Spike = game over
      if (platform.type == PlatformType.spike) {
        _triggerGameOver();
        return;
      }

      final shouldBounce = platform.onPlayerBounce();
      if (shouldBounce) {
        final jumpSpeed = platform.type == PlatformType.booster
            ? kJumpVelocity * BoosterPlatform.boostMultiplier
            : kJumpVelocity;
        // In antigravity: no bounce — just clear velocity so the character
        // gently drifts upward with the weak antigravity force (floaty space feel).
        // In normal gravity: standard bounce upward.
        player.velocityY = isNormalForCollision ? -jumpSpeed : 0;

        // Snap to the surface used for this collision
        if (isNormalForCollision) {
          player.y = platform.bounds.top - player.bounds.height / 2 - 0.5;
        } else {
          player.y = platform.bounds.bottom + player.bounds.height / 2 + 0.5;
        }

        player.onBounce();
        if (platform.type == PlatformType.booster) {
          _boosterPlayer.play(AssetSource('audio/jump_item.wav'));
        } else if (gravity.isNormal) {
          // In antigravity, sound plays once on entry — skip per-collision sound
          _playBounce();
        }

        // ── 착지 이벤트 훅 ────────────────────────────────────────────────
        _advanceTutorial(TutorialStep.jump);
        _consecutiveLands++;
        comboManager.onLand();
        missionManager.onConsecutivePlatform(_consecutiveLands);
        achievementManager.onPlatformLand(_consecutiveLands);
        achievementManager.onComboReached(comboManager.combo);
        missionManager.onCombo(comboManager.combo);

      }
    }
  }

  void _checkGameOver() {
    if (gravity.isNormal) {
      final bottomEdge = cameraY + screenHeight;
      // Bonus chance: only when clearly off screen (kCharacterSize*2 = 80px margin)
      if (!_bonusChanceUsed && player.y > bottomEdge + kCharacterSize * 2) {
        _bonusChanceUsed = true;
        _bonusChanceActive = true;
        _bonusChanceTimer = 2.2;
        final p = NormalPlatform(x: player.x, y: player.y + kCharacterSize * 0.8);
        platforms.add(p);
        _spawnCoinsForPlatform(p, allowMagnet: false);
        notifyListeners();
        return; // 같은 프레임에 게임오버 발동 방지
      }
      // Actual game over: well past screen bottom and bonus already used (or not applicable)
      if (_bonusChanceUsed && player.y > bottomEdge + kCharacterSize * 5) {
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
    if (gameState == GameState.dying || gameState == GameState.gameOver) return;
    gameState = GameState.dying;
    _dyingTimer = 0.6;

    // Death effects: big red flash + strong shake + explosion particles
    _flashAlpha = 0.85;
    _flashColor = const Color(0xFFFF1744);
    _shakeTimer = 0.6;
    _spawnDeathParticles();

    notifyListeners();
  }

  void _finalizeGameOver() {
    gameState = GameState.gameOver;
    comboManager.onBreak();
    scoreManager.saveHighScore();
    _gameOverPlayer.play(AssetSource('audio/over.wav'));
    final finalScore = scoreManager.displayScore;
    coinManager.commitSession().then((_) {
      comboManager.commitSession();
      achievementManager.onGameOver(finalScore);
      missionManager.onGameOver(finalScore);
      checkScoreUnlocks(scoreManager.displayHighScore);
    });
    notifyListeners();
  }

  void _spawnDeathParticles() {
    final colors = [
      const Color(0xFFFF1744),
      const Color(0xFFFF6D00),
      const Color(0xFFFFD600),
      Colors.white,
      const Color(0xFFFF4081),
    ];
    for (int i = 0; i < 50; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 420 + 80;
      _particles.add(_Particle(
        x: player.x,
        y: player.y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 100,
        color: colors[_rng.nextInt(colors.length)],
        size: _rng.nextDouble() * 6 + 3,
      ));
    }
  }

  /// Revive after watching a rewarded ad. Keeps score/platforms/camera intact.
  void revive() {
    hasUsedRevive = true;
    gravity.reset();

    // Reposition player to a safe visible area (screen center-bottom region)
    // so _checkGameOver doesn't immediately re-fire after resume
    player.x = screenWidth / 2;
    player.y = cameraY + screenHeight * 0.6;
    player.velocityY = -kJumpVelocity;
    player.velocityX = 0;
    _coinRainActive = false;
    _coinRainTimer = 0;

    // Clear all hazards so the player doesn't immediately die on revival
    _lasers.clear();
    _meteors.clear();
    _blackHoles.clear();
    _junkBots.clear();
    _hazardDelay = 2.0; // 2s grace period before any hazard can spawn/activate

    // Spawn a guaranteed platform just below the repositioned player
    final platY = player.y + kCharacterSize * 0.8;
    final p = NormalPlatform(x: player.x, y: platY);
    platforms.add(p);
    _spawnCoinsForPlatform(p, allowMagnet: false);

    gameState = GameState.playing;
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
    final score = scoreManager.displayScore;
    double baseGap;
    double minGapClamp;

    if (score < 150) {
      baseGap = 60.0; // Stair-like dense spacing until 150 pts
      minGapClamp = 50.0;
    } else if (score < 800) {
      baseGap = kBasePlatformGap + (score * 0.12) - 30;
      minGapClamp = kMinPlatformGap;
    } else {
      baseGap = kBasePlatformGap + (score * 0.15);
      minGapClamp = kMinPlatformGap;
    }

    final minG = (baseGap * 0.7).clamp(minGapClamp, kMaxPlatformGap);
    final maxG = (baseGap * 1.3).clamp(minGapClamp, kMaxPlatformGap);

    double y = fromY;
    while (y < toY) {
      final gap = _rng.nextDouble() * (maxG - minG) + minG;
      y += gap;
      _spawnPlatformAt(y);
    }
    _lowestGeneratedY = y;
  }

  void _generatePlatformsUpward(double fromY, double toY) {
    final score = scoreManager.displayScore;
    double baseGap;
    double minGapClamp;

    if (score < 150) {
      baseGap = 60.0;
      minGapClamp = 50.0;
    } else if (score < 800) {
      baseGap = kBasePlatformGap + (score * 0.12) - 30;
      minGapClamp = kMinPlatformGap;
    } else {
      baseGap = kBasePlatformGap + (score * 0.15);
      minGapClamp = kMinPlatformGap;
    }

    final minG = (baseGap * 0.7).clamp(minGapClamp, kMaxPlatformGap);
    final maxG = (baseGap * 1.3).clamp(minGapClamp, kMaxPlatformGap);

    double y = fromY;
    while (y > toY) {
      final gap = _rng.nextDouble() * (maxG - minG) + minG;
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
    _spawnCoinsForPlatform(p);

    // Laser traps: appear at score >= 300, small probability
    if (score >= 300 && _rng.nextDouble() < 0.12) {
      // Place the laser between this platform and the one above (~half a gap up)
      final laserY = worldY - 55.0;
      _lasers.add(LaserTrap(x: 0, y: laserY, width: screenWidth));
    }
  }

  void _spawnCoinsForPlatform(GamePlatform p, {bool allowMagnet = true}) {
    if (p.type == PlatformType.spike || p.type == PlatformType.breaking) return;

    final cx = p.x;
    final cy = p.y - 24; // 플랫폼 바로 위 24px
    final roll = _rng.nextDouble();

    if (roll < 0.30) {
      // 패턴 A: 수평 3개 (플랫폼 위)
      for (int i = 0; i < 3; i++) {
        coins.add(CoinComponent(x: cx + (i - 1) * 26.0, y: cy));
      }
    } else if (roll < 0.55) {
      // 패턴 B: 수직 라인 4개
      for (int i = 0; i < 4; i++) {
        coins.add(CoinComponent(x: cx, y: cy - i * 28.0));
      }
    } else if (roll < 0.70) {
      // 패턴 C: 대각선 유도 4개
      for (int i = 0; i < 4; i++) {
        coins.add(CoinComponent(x: cx + i * 24.0, y: cy - i * 28.0));
      }
    } else if (roll < 0.80) {
      // 패턴 D: 큰 코인 1개 (5배)
      coins.add(CoinComponent(x: cx, y: cy, isBigCoin: true));
    }
    // 20%: 없음

    // 자석 아이템 (6% 확률)
    if (allowMagnet && _rng.nextDouble() < 0.06) {
      magnets.add(MagnetItem(x: cx + (_rng.nextDouble() - 0.5) * 40, y: cy - 20));
    }
    // 쉴드 아이템 (3% 확률, score >= 50)
    if (allowMagnet && scoreManager.displayScore >= 50 && _rng.nextDouble() < 0.03) {
      _shieldItems.add(ShieldItem(x: cx + (_rng.nextDouble() - 0.5) * 50, y: cy - 28));
    }
  }

  GamePlatform _pickPlatformType(int score, double x, double y) {
    final roll = _rng.nextDouble();
    if (score < 70) {
      // 100% normal
      return NormalPlatform(x: x, y: y);
    } else if (score < 100) {
      // 84% normal, 10% booster, 6% crystal
      if (roll < 0.84) return NormalPlatform(x: x, y: y);
      if (roll < 0.94) return BoosterPlatform(x: x, y: y);
      return CrystalPlatform(x: x, y: y);
    } else if (score < 400) {
      // 55% normal, 25% moving, 12% booster, 8% crystal
      if (roll < 0.55) return NormalPlatform(x: x, y: y);
      if (roll < 0.80) return MovingPlatform(x: x, y: y, screenWidth: screenWidth);
      if (roll < 0.92) return BoosterPlatform(x: x, y: y);
      return CrystalPlatform(x: x, y: y);
    } else if (score < 600) {
      // 46% normal, 18% moving, 18% breaking, 10% gravity pad, 8% crystal
      if (roll < 0.46) return NormalPlatform(x: x, y: y);
      if (roll < 0.64) return MovingPlatform(x: x, y: y, screenWidth: screenWidth);
      if (roll < 0.82) return BreakingPlatform(x: x, y: y);
      if (roll < 0.92) return GravityPadPlatform(x: x, y: y, gravitySystem: gravity, score: score);
      return CrystalPlatform(x: x, y: y);
    } else if (score < 900) {
      // 37% normal, 18% moving, 18% breaking, 9% booster, 10% gravity pad, 8% crystal
      if (roll < 0.37) return NormalPlatform(x: x, y: y);
      if (roll < 0.55) return MovingPlatform(x: x, y: y, screenWidth: screenWidth);
      if (roll < 0.73) return BreakingPlatform(x: x, y: y);
      if (roll < 0.82) return BoosterPlatform(x: x, y: y);
      if (roll < 0.92) return GravityPadPlatform(x: x, y: y, gravitySystem: gravity, score: score);
      return CrystalPlatform(x: x, y: y);
    } else {
      // 23% normal, 18% moving, 18% breaking, 13% booster, 9% gravity pad, 10% spike, 8% crystal (rolls beyond 0.90 → crystal else spike)
      if (roll < 0.23) return NormalPlatform(x: x, y: y);
      if (roll < 0.41) return MovingPlatform(x: x, y: y, screenWidth: screenWidth);
      if (roll < 0.59) return BreakingPlatform(x: x, y: y);
      if (roll < 0.72) return BoosterPlatform(x: x, y: y);
      if (roll < 0.81) return GravityPadPlatform(x: x, y: y, gravitySystem: gravity, score: score);
      if (roll < 0.92) return SpikePlatform(x: x, y: y);
      return CrystalPlatform(x: x, y: y);
    }
  }

  void _cullPlatforms() {
    platforms.removeWhere((p) {
      if (gravity.isNormal) {
        return p.y > cameraY + screenHeight * 3;
      } else {
        return p.y < cameraY - screenHeight * 3;
      }
    });
  }

  // ─── Input ────────────────────────────────────────────────────────────────

  void onTap() {
    if (gameState != GameState.playing) return;
    final flipped = gravity.tryFlip(scoreManager.displayScore);
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
    // Nudge player in the new gravity direction so they clear the platform
    // surface they just bounced off, preventing wrong-side re-collision.
    // gravity.isNormal reflects the NEW state at this point.
    if (gravity.isNormal) {
      player.y += 6; // now falls down — push away from ceiling platforms
    } else {
      player.y -= 6; // now rises up — push away from floor platforms
      // Damp any high velocity so the player starts with a gentle drift upward
      player.velocityY = player.velocityY.clamp(-120.0, 60.0);
      // Play antigravity sound once on entry
      _bouncePlayer.play(AssetSource('audio/Anti.wav'));
    }

    _flashAlpha = 0.35;
    _flashColor = gravity.isNormal ? const Color(0xFF42A5F5) : const Color(0xFFAB47BC);
    _shakeTimer = 0.2; // 200ms shake
    _spawnFlipParticles();
    _consecutiveLands = 0; // 착지 연속 초기화
    _advanceTutorial(TutorialStep.gravity);
    comboManager.onBreak();
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
    canvas.save();
    if (_shakeTimer > 0) {
      // Death shake uses a 0.6s timer, flip shake uses 0.2s — normalize accordingly
      final maxShake = gameState == GameState.dying ? 0.6 : 0.2;
      final intensity = (_shakeTimer / maxShake).clamp(0.0, 1.0) * 12;
      canvas.translate(
        (_rng.nextDouble() - 0.5) * intensity,
        (_rng.nextDouble() - 0.5) * intensity,
      );
    }

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

    // Draw laser traps
    for (final l in _lasers) {
      l.draw(canvas);
    }

    // Draw coins
    for (final c in coins) {
      c.draw(canvas);
    }

    // Draw magnets
    for (final m in magnets) {
      m.draw(canvas);
    }

    // Draw shield items
    for (final s in _shieldItems) {
      s.draw(canvas);
    }

    // ── Antigravity ghost trail ──
    if (!gravity.isNormal && _ghostTrail.isNotEmpty) {
      for (int i = 0; i < _ghostTrail.length; i++) {
        final age = i / _ghostTrail.length; // 0=oldest, 1=newest
        final alpha = age * 0.45;
        final radius = kCharacterSize * 0.5 * (0.5 + age * 0.5);
        final ghostPaint = Paint()
          ..color = const Color(0xFFCE93D8).withValues(alpha: alpha)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(_ghostTrail[i], radius, ghostPaint);
      }
    }

    // Draw player (with skin)
    skinRenderer.draw(canvas, player.x, player.y, gravity.isNormal);

    // ── Shield visual ──
    if (isShielded) {
      final blink = _shieldTimer < 1.0 && ((_shieldTimer * 8).floor() % 2 == 0);
      if (!blink) {
        final shieldAlpha = (_shieldTimer / ShieldItem.shieldDuration).clamp(0.3, 0.8);
        // Outer glow
        final glowPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: shieldAlpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(Offset(player.x, player.y), kCharacterSize * 1.2, glowPaint);
        // Rotating ring
        canvas.save();
        canvas.translate(player.x, player.y);
        canvas.rotate(_electricTimer * 2.5);
        final ringPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: shieldAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: kCharacterSize * 1.0),
            0, 3.14159 * 1.5, false, ringPaint);
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: kCharacterSize * 1.0),
            3.14159 * 1.7, 3.14159 * 1.5, false, ringPaint);
        canvas.restore();
        // Inner shield solid ring
        final innerPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: shieldAlpha * 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawCircle(Offset(player.x, player.y), kCharacterSize * 0.85, innerPaint);
      }
    }

    // ── Antigravity purple aura ──
    if (!gravity.isNormal) {
      final pulse = 0.7 + 0.3 * sin(_electricTimer * 2.5);
      final auraPaint = Paint()
        ..color = const Color(0xFFAB47BC).withValues(alpha: 0.30 * pulse.abs())
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(Offset(player.x, player.y), kCharacterSize * 0.85, auraPaint);
      final rimPaint = Paint()
        ..color = const Color(0xFFE040FB).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(player.x, player.y), kCharacterSize * 0.72, rimPaint);
    }

    // 자석 활성 링
    if (magnetActive) {
      final ringPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(player.x, player.y), 52, ringPaint);
      final innerPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(Offset(player.x, player.y), 40, innerPaint);
    }

    // Draw meteors
    for (final m in _meteors) {
      m.draw(canvas);
    }

    // Draw black holes
    for (final bh in _blackHoles) {
      bh.draw(canvas);
    }

    // Draw junk bots
    for (final jb in _junkBots) {
      jb.draw(canvas);
    }

    // Draw particles
    for (final p in _particles) {
      p.draw(canvas);
    }

    canvas.restore();

    // ── Electric ceiling barrier (antigravity death zone) ──
    if (!gravity.isNormal) {
      _drawElectricCeiling(canvas, size);
    }

    // ── 운석 경고 표시 (! 아이콘 화면 상단) ──
    if (_meteorWarnings.isNotEmpty) {
      for (final w in _meteorWarnings) {
        final fraction = w.timer / _MeteorWarning.duration;
        // 빠른 깜빡임 (fraction 1→0 감소하면서 점점 빠르게)
        final blinkPhase = sin(w.timer * (6 + (1 - fraction) * 10) * 3.14159);
        final alpha = (blinkPhase.abs() * 0.9 + 0.1).clamp(0.0, 1.0);

        // 느낌표 배경 원
        final bgPaint = Paint()
          ..color = const Color(0xFFFF3D00).withValues(alpha: alpha * 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(w.x, 28), 18, bgPaint);

        // 느낌표 텍스트
        final textPainter = TextPainter(
          text: TextSpan(
            text: '!',
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withValues(alpha: alpha),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: const Color(0xFFFF3D00), blurRadius: 6)],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(w.x - textPainter.width / 2, 28 - textPainter.height / 2),
        );

        // 아래로 향하는 삼각형 화살표
        final arrowPaint = Paint()
          ..color = const Color(0xFFFF3D00).withValues(alpha: alpha * 0.85)
          ..style = PaintingStyle.fill;
        final arrowPath = Path()
          ..moveTo(w.x - 8, 48)
          ..lineTo(w.x + 8, 48)
          ..lineTo(w.x, 60)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }

    // Screen flash (gravity flip or death)
    if (_flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = _flashColor.withAlpha((_flashAlpha * 255).toInt()),
      );
    }

    canvas.restore(); // Restore shake save
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

  // ─── Meteors ──────────────────────────────────────────────────────────────

  // 현재 활성화된 위험 요소 총합 (2개 이상이면 스폰 억제)
  int get _totalActiveHazards =>
      _meteors.length + _blackHoles.length + _junkBots.length + _meteorWarnings.length;

  void _updateMeteors(double dt) {
    if (_hazardDelay > 0) return;
    final score = scoreManager.displayScore;
    if (score < 120) return;

    final double spawnInterval = score < 300 ? 6.0 : score < 600 ? 4.0 : 2.5;

    // 경고 업데이트 → 경고 시간 끝나면 실제 운석 스폰
    for (int i = _meteorWarnings.length - 1; i >= 0; i--) {
      final w = _meteorWarnings[i];
      w.timer -= dt;
      if (w.timer <= 0) {
        _meteorWarnings.removeAt(i);
        _meteors.add(Meteor(
          x: w.x,
          y: cameraY - 30,
          speed: w.speed,
          radius: w.radius,
          angle: w.angle,
        ));
      }
    }

    _meteorSpawnTimer -= dt;
    if (_meteorSpawnTimer <= 0) {
      _meteorSpawnTimer = spawnInterval * (0.7 + _rng.nextDouble() * 0.6);
      // 동시 위험 요소 최대 2개 제한
      if (_totalActiveHazards < 2) {
        final radius = 22.0 + _rng.nextDouble() * 14;
        final spawnX = radius + _rng.nextDouble() * (screenWidth - radius * 2);
        final speed = 180.0 + _rng.nextDouble() * 80;
        final angle = (_rng.nextDouble() - 0.5) * 0.6;
        // 운석 스폰 전 1.5초 경고 표시
        _meteorWarnings.add(_MeteorWarning(
          x: spawnX,
          radius: radius,
          speed: speed,
          angle: angle,
        ));
      }
    }

    for (final m in _meteors) {
      m.update(dt);
      if (!m.active) continue;
      if (player.bounds.overlaps(m.bounds)) {
        if (isShielded) { m.active = false; continue; } // 쉴드: 운석 파괴
        _triggerGameOver();
        return;
      }
    }
    _meteors.removeWhere((m) => m.y > cameraY + screenHeight + 100);
  }

  // ─── Lasers ───────────────────────────────────────────────────────────────

  void _updateLasers(double dt) {
    for (final l in _lasers) {
      l.update(dt);
      if (_hazardDelay > 0) continue;
      if (l.isActive && player.bounds.overlaps(l.bounds)) {
        if (isShielded) continue; // 쉴드: 레이저 무시
        _triggerGameOver();
        return;
      }
    }
  }

  // ─── Tutorial ─────────────────────────────────────────────────────────────

  void _startTutorialWithTimeout() {
    _tutorialTimer?.cancel();
    if (_tutorialStep == TutorialStep.done) return;
    // 각 스텝마다 6초 타임아웃, 시간 초과시 다음 스텝으로 자동 이동
    _tutorialTimer = Timer(const Duration(seconds: 6), () {
      if (_tutorialStep != TutorialStep.done) {
        _advanceTutorial(_tutorialStep);
      }
    });
  }

  void _advanceTutorial(TutorialStep from) {
    if (_tutorialStep != from) return;
    switch (from) {
      case TutorialStep.move:
        _tutorialStep = TutorialStep.jump;
      case TutorialStep.jump:
        _tutorialStep = TutorialStep.gravity;
      case TutorialStep.gravity:
        _tutorialStep = TutorialStep.coin;
      case TutorialStep.coin:
        _tutorialStep = TutorialStep.done;
        _tutorialTimer?.cancel();
        PersistenceManager.instance.setFirstRunDone();
      case TutorialStep.done:
        break;
    }
    // 다음 스텝이 있으면 타이머 재시작
    if (_tutorialStep != TutorialStep.done) {
      _startTutorialWithTimeout();
    }
    notifyListeners();
  }

  // ─── Black Holes ──────────────────────────────────────────────────────────

  void _updateBlackHoles(double dt) {
    if (_hazardDelay > 0) return;
    final score = scoreManager.displayScore;
    if (score < 350) return; // 기존 200 → 350으로 상향

    final spawnInterval = score < 500 ? 10.0 : score < 800 ? 7.0 : 5.0;
    _blackHoleSpawnTimer -= dt;
    if (_blackHoleSpawnTimer <= 0) {
      _blackHoleSpawnTimer = spawnInterval * (0.8 + _rng.nextDouble() * 0.4);
      if (_totalActiveHazards < 2) {
        final bhX = 60.0 + _rng.nextDouble() * (screenWidth - 120);
        final bhY = cameraY + screenHeight * (0.2 + _rng.nextDouble() * 0.6);
        _blackHoles.add(BlackHole(x: bhX, y: bhY));
      }
    }

    for (final bh in _blackHoles) {
      bh.update(dt);
      if (!bh.isActive) continue;
      if (!isShielded) {
        final (dvx, dvy) = bh.getPullDelta(player.x, player.y, gravity.isNormal, dt);
        player.velocityX += dvx;
        player.velocityY += dvy;
      }
      if (player.bounds.overlaps(bh.bounds)) {
        if (isShielded) continue; // 쉴드: 블랙홀 무시
        _triggerGameOver();
        return;
      }
    }
    _blackHoles.removeWhere((bh) =>
        bh.y < cameraY - screenHeight || bh.y > cameraY + screenHeight * 2);
  }

  // ─── Junk Bots ────────────────────────────────────────────────────────────

  void _updateJunkBots(double dt) {
    if (_hazardDelay > 0) return;
    final score = scoreManager.displayScore;
    if (score < 200) return; // 기존 150 → 200으로 상향

    final spawnInterval = score < 400 ? 8.0 : score < 700 ? 5.5 : 3.5;
    _junkBotSpawnTimer -= dt;
    if (_junkBotSpawnTimer <= 0) {
      _junkBotSpawnTimer = spawnInterval * (0.7 + _rng.nextDouble() * 0.6);
      if (_totalActiveHazards < 2) {
        final botY = cameraY + screenHeight * (0.3 + _rng.nextDouble() * 0.5);
        _junkBots.add(JunkBot(x: screenWidth / 2, y: botY, screenWidth: screenWidth));
      }
    }

    for (final jb in _junkBots) {
      jb.update(dt, screenWidth);
      if (!jb.isActive) continue;
      if (player.bounds.overlaps(jb.bounds)) {
        if (isShielded) continue; // 쉴드: 봇 무시
        _triggerGameOver();
        return;
      }
    }
    _junkBots.removeWhere((jb) =>
        jb.y < cameraY - screenHeight || jb.y > cameraY + screenHeight * 2);
  }

  // ─── Audio ────────────────────────────────────────────────────────────────

  void _playBounce() {
    final sound = gravity.isNormal ? 'audio/Jump.wav' : 'audio/Anti.wav';
    _bouncePlayer.play(AssetSource(sound));
  }

  void _playFlip() {
    // _flipPlayer.play(AssetSource('audio/flip.mp3'));
  }

  @override
  void dispose() {
    _bouncePlayer.dispose();
    _flipPlayer.dispose();
    _gameOverPlayer.dispose();
    _boosterPlayer.dispose();
    super.dispose();
  }
}

// ─── Meteor Warning ─────────────────────────────────────────────────────────

class _MeteorWarning {
  double x;
  double timer;
  final double radius;
  final double speed;
  final double angle;
  static const double duration = 1.5;

  _MeteorWarning({
    required this.x,
    required this.radius,
    required this.speed,
    required this.angle,
  }) : timer = duration;
}

// ─── Particle ───────────────────────────────────────────────────────────────

class _Particle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  double life = 1.0;
  static const double _decay = 2.0;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.size = 4.0,
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
    canvas.drawCircle(Offset(x, y), size * life.clamp(0, 1), paint);
  }
}
