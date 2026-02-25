import 'package:flutter/material.dart';
import 'achievement_model.dart';
import 'achievement_catalog.dart';
import '../economy/persistence_manager.dart';
import '../economy/coin_manager.dart';

/// 업적 진행도 추적, 완료 처리, 보상 지급
class AchievementManager extends ChangeNotifier {
  final PersistenceManager _pm = PersistenceManager.instance;
  final CoinManager coinManager;

  late List<Achievement> achievements;

  // 이번 세션에서 새로 달성된 업적 큐 (팝업용)
  final List<Achievement> _pendingPopups = [];
  List<Achievement> get pendingPopups => List.unmodifiable(_pendingPopups);

  // 이번 세션의 중력 뒤집기 횟수
  int _sessionFlips = 0;
  // 이번 세션 단일 최고 점수
  int _sessionBestScore = 0;

  AchievementManager({required this.coinManager});

  Future<void> init() async {
    achievements = buildAchievementCatalog();
    final progress = _pm.achievementProgress;
    final completed = _pm.completedAchievements;

    for (final a in achievements) {
      a.currentProgress = progress[a.id] ?? 0;
      a.isCompleted = completed.contains(a.id);
    }
  }

  void resetSession() {
    _sessionFlips = 0;
    _sessionBestScore = 0;
  }

  // ── 외부 훅 ───────────────────────────────────────────────────────────────

  void onGravityFlip() {
    _sessionFlips++;
    _incrementPersisted(AchievementCondition.gravityFlipCount, 1);
    _checkAll();
  }

  void onPlatformLand(int consecutiveCount) {
    _checkSingleCond(AchievementCondition.consecutivePlatforms, consecutiveCount);
  }

  void onComboReached(int combo) {
    _checkSingleCond(AchievementCondition.maxComboReached, combo);
  }

  void onScoreUpdate(int score) {
    if (score > _sessionBestScore) {
      _sessionBestScore = score;
      _checkSingleCond(AchievementCondition.singleRunScore, score);
    }
  }

  Future<void> onGameOver(int finalScore) async {
    // 총 게임 수 증가
    await _pm.incrementStatTotalGames();
    await _pm.addStatTotalScore(finalScore);
    // 통계 기반 업적 체크
    _checkSingleCond(AchievementCondition.totalGamesPlayed, _pm.statTotalGames);
    _checkSingleCond(AchievementCondition.totalScore, _pm.statTotalScore);
    // 중력 뒤집기 누적 저장
    await _pm.addStatTotalFlips(_sessionFlips);
    _checkSingleCond(
        AchievementCondition.gravityFlipCount, _pm.statTotalFlips);
    // 코인 수집 총합
    _checkSingleCond(
        AchievementCondition.totalCoinsCollected, _pm.statTotalCoinsEver);
    await _saveProgress();
    notifyListeners();
  }

  void onCoinsCollected(int total) {
    _checkSingleCond(AchievementCondition.totalCoinsCollected, total);
  }

  void onDailyMissionCompleted(int totalCompleted) {
    _checkSingleCond(AchievementCondition.dailyMissionsTotal, totalCompleted);
  }

  // ── 내부 로직 ─────────────────────────────────────────────────────────────

  void _incrementPersisted(AchievementCondition cond, int delta) {
    for (final a in achievements) {
      if (a.condition == cond && !a.isCompleted) {
        a.currentProgress += delta;
      }
    }
  }

  void _checkSingleCond(AchievementCondition cond, int currentValue) {
    for (final a in achievements) {
      if (a.condition == cond && !a.isCompleted) {
        if (currentValue > a.currentProgress) {
          a.currentProgress = currentValue;
        }
        if (a.currentProgress >= a.targetValue) {
          _complete(a);
        }
      }
    }
  }

  void _checkAll() {
    for (final a in achievements) {
      if (!a.isCompleted && a.currentProgress >= a.targetValue) {
        _complete(a);
      }
    }
  }

  void _complete(Achievement a) {
    if (a.isCompleted) return;
    a.isCompleted = true;
    _pendingPopups.add(a);
    // 코인 보상
    if (a.rewardCoins > 0) {
      coinManager.addDirect(a.rewardCoins);
    }
    // 스킨 해금
    if (a.rewardSkinId != null) {
      final unlocked = List<String>.from(_pm.unlockedSkins);
      if (!unlocked.contains(a.rewardSkinId)) {
        unlocked.add(a.rewardSkinId!);
        _pm.setUnlockedSkins(unlocked);
      }
    }
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final progressMap = <String, int>{};
    final completedList = <String>[];
    for (final a in achievements) {
      progressMap[a.id] = a.currentProgress;
      if (a.isCompleted) completedList.add(a.id);
    }
    await _pm.setAchievementProgress(progressMap);
    await _pm.setCompletedAchievements(completedList);
  }

  /// 팝업 큐에서 맨 앞 항목을 꺼냄
  Achievement? popPopup() {
    if (_pendingPopups.isEmpty) return null;
    return _pendingPopups.removeAt(0);
  }
}
