import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../achievements/achievement_model.dart';
import '../economy/persistence_manager.dart';

enum MissionDifficulty { easy, medium, hard }

class DailyMission {
  final String id;
  final String description;
  final AchievementCondition condition;
  final int targetValue;
  final int rewardCoins;
  final MissionDifficulty difficulty;
  int currentProgress;
  bool isCompleted;
  final DateTime expiresAt; // 당일 자정

  DailyMission({
    required this.id,
    required this.description,
    required this.condition,
    required this.targetValue,
    required this.rewardCoins,
    required this.difficulty,
    required this.expiresAt,
    this.currentProgress = 0,
    this.isCompleted = false,
  });

  double get progressFraction => (currentProgress / targetValue).clamp(0.0, 1.0);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'condition': condition.name,
        'targetValue': targetValue,
        'rewardCoins': rewardCoins,
        'difficulty': difficulty.name,
        'currentProgress': currentProgress,
        'isCompleted': isCompleted,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory DailyMission.fromJson(Map<String, dynamic> j) {
    return DailyMission(
      id: j['id'] as String,
      description: j['description'] as String,
      condition: AchievementCondition.values
          .firstWhere((e) => e.name == j['condition']),
      targetValue: j['targetValue'] as int,
      rewardCoins: j['rewardCoins'] as int,
      difficulty: MissionDifficulty.values
          .firstWhere((e) => e.name == j['difficulty']),
      expiresAt: DateTime.parse(j['expiresAt'] as String),
      currentProgress: j['currentProgress'] as int,
      isCompleted: j['isCompleted'] as bool,
    );
  }
}

// ── 미션 풀 ──────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _missionPool = [
  // easy
  {'desc': '오늘 3판 플레이', 'cond': AchievementCondition.totalGamesPlayed, 'target': 3, 'coins': 20, 'diff': MissionDifficulty.easy},
  {'desc': '오늘 5판 플레이', 'cond': AchievementCondition.totalGamesPlayed, 'target': 5, 'coins': 25, 'diff': MissionDifficulty.easy},
  {'desc': '오늘 코인 30개 수집', 'cond': AchievementCondition.totalCoinsCollected, 'target': 30, 'coins': 20, 'diff': MissionDifficulty.easy},
  {'desc': '오늘 중력 10번 뒤집기', 'cond': AchievementCondition.gravityFlipCount, 'target': 10, 'coins': 20, 'diff': MissionDifficulty.easy},
  // medium
  {'desc': '오늘 단일 게임 500점 달성', 'cond': AchievementCondition.singleRunScore, 'target': 500, 'coins': 30, 'diff': MissionDifficulty.medium},
  {'desc': '오늘 중력 20번 뒤집기', 'cond': AchievementCondition.gravityFlipCount, 'target': 20, 'coins': 25, 'diff': MissionDifficulty.medium},
  {'desc': '오늘 연속 플랫폼 15개 착지', 'cond': AchievementCondition.consecutivePlatforms, 'target': 15, 'coins': 35, 'diff': MissionDifficulty.medium},
  {'desc': '오늘 코인 50개 수집', 'cond': AchievementCondition.totalCoinsCollected, 'target': 50, 'coins': 30, 'diff': MissionDifficulty.medium},
  {'desc': '오늘 콤보 x10 달성', 'cond': AchievementCondition.maxComboReached, 'target': 10, 'coins': 35, 'diff': MissionDifficulty.medium},
  // hard
  {'desc': '오늘 단일 게임 1000점 달성', 'cond': AchievementCondition.singleRunScore, 'target': 1000, 'coins': 50, 'diff': MissionDifficulty.hard},
  {'desc': '오늘 중력 40번 뒤집기', 'cond': AchievementCondition.gravityFlipCount, 'target': 40, 'coins': 45, 'diff': MissionDifficulty.hard},
  {'desc': '오늘 콤보 x20 달성', 'cond': AchievementCondition.maxComboReached, 'target': 20, 'coins': 50, 'diff': MissionDifficulty.hard},
  {'desc': '오늘 코인 100개 수집', 'cond': AchievementCondition.totalCoinsCollected, 'target': 100, 'coins': 45, 'diff': MissionDifficulty.hard},
  {'desc': '오늘 연속 플랫폼 25개 착지', 'cond': AchievementCondition.consecutivePlatforms, 'target': 25, 'coins': 40, 'diff': MissionDifficulty.hard},
];

// ── 미션 매니저 ───────────────────────────────────────────────────────────────

class DailyMissionManager extends ChangeNotifier {
  final PersistenceManager _pm = PersistenceManager.instance;

  List<DailyMission> _missions = [];
  List<DailyMission> get missions => List.unmodifiable(_missions);

  // 이번 세션 통계 추적 (미션 체크용)
  int _sessionGamesPlayed = 0;
  int _sessionFlips = 0;
  int _sessionCoins = 0;
  int _sessionMaxCombo = 0;
  int _sessionBestScore = 0;
  int _sessionMaxConsecutive = 0;

  Future<void> init() async {
    await _pm.init();
    await _loadOrGenerate();
  }

  Future<void> _loadOrGenerate() async {
    final json = _pm.dailyMissionJson;
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        _missions = list
            .map((e) => DailyMission.fromJson(e as Map<String, dynamic>))
            .toList();
        // 만료된 경우 새로 생성
        if (_missions.isNotEmpty && _missions.first.isExpired) {
          await _generate();
        }
      } catch (_) {
        await _generate();
      }
    } else {
      await _generate();
    }
    notifyListeners();
  }

  Future<void> _generate() async {
    final midnight = _nextMidnight();
    final rng = Random();
    final pool = List.of(_missionPool)..shuffle(rng);
    _missions = pool.take(3).toList().asMap().entries.map((e) {
      final m = e.value;
      return DailyMission(
        id: 'daily_${e.key}',
        description: m['desc'] as String,
        condition: m['cond'] as AchievementCondition,
        targetValue: m['target'] as int,
        rewardCoins: m['coins'] as int,
        difficulty: m['diff'] as MissionDifficulty,
        expiresAt: midnight,
      );
    }).toList();
    await _save();
  }

  DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Future<void> _save() async {
    final json = jsonEncode(_missions.map((m) => m.toJson()).toList());
    await _pm.setDailyMissionJson(json);
  }

  // ── 세션 훅 ──────────────────────────────────────────────────────────────

  void resetSession() {
    _sessionGamesPlayed = 0;
    _sessionFlips = 0;
    _sessionCoins = 0;
    _sessionMaxCombo = 0;
    _sessionBestScore = 0;
    _sessionMaxConsecutive = 0;
  }

  void onGameOver(int score) {
    _sessionGamesPlayed++;
    if (score > _sessionBestScore) _sessionBestScore = score;
    _checkAll();
  }

  void onFlip() {
    _sessionFlips++;
    _checkAll();
  }

  void onCoinCollected() {
    _sessionCoins++;
    _checkAll();
  }

  void onCombo(int combo) {
    if (combo > _sessionMaxCombo) _sessionMaxCombo = combo;
    _checkAll();
  }

  void onConsecutivePlatform(int count) {
    if (count > _sessionMaxConsecutive) _sessionMaxConsecutive = count;
    _checkAll();
  }

  void _checkAll() {
    bool changed = false;
    for (final m in _missions) {
      if (m.isCompleted) continue;
      int val = _getSessionValue(m.condition);
      if (val > m.currentProgress) {
        m.currentProgress = val;
        if (m.currentProgress >= m.targetValue) {
          m.isCompleted = true;
          changed = true;
        }
      }
    }
    if (changed) {
      _save();
      notifyListeners();
    }
  }

  int _getSessionValue(AchievementCondition cond) {
    switch (cond) {
      case AchievementCondition.totalGamesPlayed: return _sessionGamesPlayed;
      case AchievementCondition.gravityFlipCount: return _sessionFlips;
      case AchievementCondition.totalCoinsCollected: return _sessionCoins;
      case AchievementCondition.maxComboReached: return _sessionMaxCombo;
      case AchievementCondition.singleRunScore: return _sessionBestScore;
      case AchievementCondition.consecutivePlatforms: return _sessionMaxConsecutive;
      default: return 0;
    }
  }

  Future<int> claimReward(DailyMission mission) async {
    if (!mission.isCompleted) return 0;
    // 이미 수령했는지 id로 체크 (isCompleted=true && rewardCoins > 0)
    await _pm.incrementTotalMissionsCompleted();
    await _save();
    return mission.rewardCoins;
  }

  Future<DailyMission?> rerollMission(int index) async {
    // 15코인 소비는 CoinManager에서 처리 후 이 함수 호출
    if (index < 0 || index >= _missions.length) return null;
    final midnight = _nextMidnight();
    final rng = Random();
    final pool = List.of(_missionPool)..shuffle(rng);
    final existing = _missions.map((m) => m.description).toSet();
    final candidate = pool.firstWhere(
      (m) => !existing.contains(m['desc']),
      orElse: () => pool.first,
    );
    _missions[index] = DailyMission(
      id: 'daily_$index',
      description: candidate['desc'] as String,
      condition: candidate['cond'] as AchievementCondition,
      targetValue: candidate['target'] as int,
      rewardCoins: candidate['coins'] as int,
      difficulty: candidate['diff'] as MissionDifficulty,
      expiresAt: midnight,
    );
    await _save();
    notifyListeners();
    return _missions[index];
  }

  int get totalMissionsCompleted => _pm.totalMissionsCompleted;
}
