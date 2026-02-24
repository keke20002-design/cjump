import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  double _currentScore = 0;
  double _highScore = 0;
  double? _highestY; // null until first update()
  bool _initialized = false;

  double get currentScore => _currentScore;
  double get highScore => _highScore;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getDouble('high_score') ?? 0;
    _initialized = true;
  }

  void reset() {
    _currentScore = 0;
    _highestY = null; // will be set on first update() call
  }

  /// Call each frame with the player's current world Y position.
  /// Lower Y = higher on screen = higher score.
  void update(double playerWorldY) {
    if (_highestY == null) {
      _highestY = playerWorldY; // initialize on first call
      return;
    }
    if (playerWorldY < _highestY!) {
      final delta = _highestY! - playerWorldY;
      _currentScore += delta * 0.1;
      _highestY = playerWorldY;
    }
  }

  Future<void> saveHighScore() async {
    if (_currentScore > _highScore) {
      _highScore = _currentScore;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('high_score', _highScore);
    }
  }

  int get displayScore => _currentScore.toInt();
  int get displayHighScore => _highScore.toInt();
}
