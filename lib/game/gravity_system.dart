import 'dart:math';
import 'package:flutter/foundation.dart';
import '../game/game_state.dart';
import '../utils/constants.dart';

class GravitySystem extends ChangeNotifier {
  GravityState _state = GravityState.normal;
  double _cooldownRemaining = 0;
  double _transitionProgress = 1.0; // 0=start of flip, 1=complete
  bool _isTransitioning = false;
  double _antiGravityTimer = 0;

  // Listeners for flip events (separate from ChangeNotifier listeners)
  final List<VoidCallback> _onFlipListeners = [];

  GravityState get state => _state;
  bool get isNormal => _state == GravityState.normal;
  bool get canFlip => _cooldownRemaining <= 0 && !_isTransitioning;
  double get cooldownFraction =>
      1.0 - (_cooldownRemaining / kGravityFlipCooldown).clamp(0.0, 1.0);
  double get transitionProgress => _transitionProgress;
  bool get isTransitioning => _isTransitioning;
  double get antiGravityTimerFraction =>
      (_antiGravityTimer / kAntiGravityDuration).clamp(0.0, 1.0);

  /// Current effective gravity direction multiplier: +1 = down, -1 = up
  double get gravityDirection => isNormal ? 1.0 : -1.0;

  /// Effective gravity force (signed, pixels/s²)
  double get effectiveGravity {
    if (_isTransitioning) {
      final t = _transitionProgress;
      final eased = t * t; // ease-in quad
      return isNormal
          ? (2 * eased - 1) * kGravityForce
          : (1 - 2 * eased) * kGravityForce;
    }
    return gravityDirection * kGravityForce;
  }

  void addFlipListener(VoidCallback cb) => _onFlipListeners.add(cb);
  void removeFlipListener(VoidCallback cb) => _onFlipListeners.remove(cb);

  bool tryFlip([int score = 0]) {
    if (!canFlip) return false;
    _state = isNormal ? GravityState.antigravity : GravityState.normal;
    _antiGravityTimer = !isNormal
        ? (kAntiGravityDuration - (score * 0.0013))
            .clamp(kMinAntiGravityDuration, kAntiGravityDuration)
        : 0;
    _cooldownRemaining =
        (kGravityFlipCooldown + (score * 0.0015)).clamp(1.5, 3.0);
    _transitionProgress = 0.0;
    _isTransitioning = true;
    for (final cb in List.of(_onFlipListeners)) {
      cb();
    }
    notifyListeners();
    return true;
  }

  /// Force flip without cooldown (used by gravity pad platform)
  void forceFlip([int score = 0]) {
    _state = isNormal ? GravityState.antigravity : GravityState.normal;
    _antiGravityTimer = !isNormal
        ? (kAntiGravityDuration - (score * 0.0013))
            .clamp(kMinAntiGravityDuration, kAntiGravityDuration)
        : 0;
    _cooldownRemaining =
        (kGravityFlipCooldown + (score * 0.0015)).clamp(1.5, 3.0) * 0.5;
    _transitionProgress = 0.0;
    _isTransitioning = true;
    for (final cb in List.of(_onFlipListeners)) {
      cb();
    }
    notifyListeners();
  }

  void update(double dt, [int currentScore = 0]) {
    bool changed = false;
    if (_cooldownRemaining > 0) {
      _cooldownRemaining = max(0, _cooldownRemaining - dt);
      changed = true;
    }
    if (_isTransitioning) {
      _transitionProgress += dt / kGravityFlipDuration;
      if (_transitionProgress >= 1.0) {
        _transitionProgress = 1.0;
        _isTransitioning = false;
      }
      changed = true;
    }

    if (!isNormal && !_isTransitioning) {
      _antiGravityTimer -= dt;

      // Difficulty: duration decreases as score increases
      // 0 score -> 2.5s, 1000 score -> 1.2s
      final dynamicDuration = (kAntiGravityDuration - (currentScore * 0.0013))
          .clamp(kMinAntiGravityDuration, kAntiGravityDuration);
      
      // If timer was just started, it might need adjustment if score changed significantly
      // but usually we just let it run.

      if (_antiGravityTimer <= 0) {
        _antiGravityTimer = 0;
        _state = GravityState.normal;
        _transitionProgress = 0.0;
        _isTransitioning = true; // Use transition to go back to normal
        for (final cb in List.of(_onFlipListeners)) {
          cb();
        }
      }
      changed = true;
    }

    if (changed) notifyListeners();
  }

  void reset() {
    _state = GravityState.normal;
    _cooldownRemaining = 0;
    _transitionProgress = 1.0;
    _isTransitioning = false;
    notifyListeners();
  }
}
