import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 모든 진행 데이터를 SharedPreferences에 저장·로드하는 싱글턴
class PersistenceManager {
  PersistenceManager._();
  static final PersistenceManager instance = PersistenceManager._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'PersistenceManager.init() must be called first');
    return _prefs!;
  }

  // ── Coins ─────────────────────────────────────────────────────────────────
  int get coins => _p.getInt(PersistenceKeys.coins) ?? 0;
  Future<void> setCoins(int v) => _p.setInt(PersistenceKeys.coins, v);

  // ── Skins ─────────────────────────────────────────────────────────────────
  List<String> get unlockedSkins =>
      _p.getStringList(PersistenceKeys.unlockedSkins) ?? ['green_core'];

  Future<void> setUnlockedSkins(List<String> v) =>
      _p.setStringList(PersistenceKeys.unlockedSkins, v);

  String get selectedSkin =>
      _p.getString(PersistenceKeys.selectedSkin) ?? 'green_core';
  Future<void> setSelectedSkin(String v) =>
      _p.setString(PersistenceKeys.selectedSkin, v);

  // ── Achievements ──────────────────────────────────────────────────────────
  Map<String, int> get achievementProgress {
    final raw = _p.getString(PersistenceKeys.achievementProgress);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw) as Map);
  }

  Future<void> setAchievementProgress(Map<String, int> v) =>
      _p.setString(PersistenceKeys.achievementProgress, jsonEncode(v));

  List<String> get completedAchievements =>
      _p.getStringList(PersistenceKeys.completedAchievements) ?? [];
  Future<void> setCompletedAchievements(List<String> v) =>
      _p.setStringList(PersistenceKeys.completedAchievements, v);

  // ── Stats ─────────────────────────────────────────────────────────────────
  int get statTotalScore => _p.getInt(PersistenceKeys.totalScore) ?? 0;
  Future<void> addStatTotalScore(int v) =>
      _p.setInt(PersistenceKeys.totalScore, statTotalScore + v);

  int get statHighScore => _p.getInt(PersistenceKeys.highScore) ?? 0;
  Future<void> setStatHighScore(int v) =>
      _p.setInt(PersistenceKeys.highScore, v);

  int get statTotalGames => _p.getInt(PersistenceKeys.totalGames) ?? 0;
  Future<void> incrementStatTotalGames() =>
      _p.setInt(PersistenceKeys.totalGames, statTotalGames + 1);

  int get statTotalFlips => _p.getInt(PersistenceKeys.totalFlips) ?? 0;
  Future<void> addStatTotalFlips(int v) =>
      _p.setInt(PersistenceKeys.totalFlips, statTotalFlips + v);

  int get statTotalCoinsEver => _p.getInt(PersistenceKeys.totalCoinsEver) ?? 0;
  Future<void> addStatTotalCoinsEver(int v) =>
      _p.setInt(PersistenceKeys.totalCoinsEver, statTotalCoinsEver + v);

  // ── Combo stat ────────────────────────────────────────────────────────────
  int get statMaxCombo => _p.getInt(PersistenceKeys.maxCombo) ?? 0;
  Future<void> setStatMaxCombo(int v) =>
      _p.setInt(PersistenceKeys.maxCombo, v);

  // ── Daily Mission ─────────────────────────────────────────────────────────
  String? get dailyMissionJson => _p.getString(PersistenceKeys.dailyMission);
  Future<void> setDailyMissionJson(String v) =>
      _p.setString(PersistenceKeys.dailyMission, v);

  int get totalMissionsCompleted =>
      _p.getInt(PersistenceKeys.totalMissionsCompleted) ?? 0;
  Future<void> incrementTotalMissionsCompleted() => _p.setInt(
      PersistenceKeys.totalMissionsCompleted, totalMissionsCompleted + 1);
  
  int get dailyMissionsCompletedDays =>
      _p.getInt(PersistenceKeys.dailyMissionsCompletedDays) ?? 0;
  Future<void> setDailyMissionsCompletedDays(int v) =>
      _p.setInt(PersistenceKeys.dailyMissionsCompletedDays, v);

  // ── Leaderboard ───────────────────────────────────────────────────────────
  String? get leaderboardJson => _p.getString(PersistenceKeys.leaderboard);
  Future<void> setLeaderboardJson(String v) =>
      _p.setString(PersistenceKeys.leaderboard, v);

  // ── Onboarding ────────────────────────────────────────────────────────────
  bool get isFirstRun => _p.getBool(PersistenceKeys.isFirstRun) ?? true;
  Future<void> setFirstRunDone() =>
      _p.setBool(PersistenceKeys.isFirstRun, false);

  int get onboardingStep => _p.getInt(PersistenceKeys.onboardingStep) ?? 0;
  Future<void> setOnboardingStep(int v) =>
      _p.setInt(PersistenceKeys.onboardingStep, v);
}

class PersistenceKeys {
  // 경제
  static const String coins = 'coins';

  // 스킨
  static const String unlockedSkins = 'unlocked_skins';
  static const String selectedSkin = 'selected_skin';

  // 업적
  static const String achievementProgress = 'achievement_progress';
  static const String completedAchievements = 'completed_achievements';

  // 통계
  static const String totalScore = 'stat_total_score';
  static const String highScore = 'stat_high_score';
  static const String totalGames = 'stat_total_games';
  static const String totalFlips = 'stat_total_flips';
  static const String totalCoinsEver = 'stat_total_coins';
  static const String maxCombo = 'stat_max_combo';

  // 데일리 미션
  static const String dailyMission = 'daily_mission';
  static const String totalMissionsCompleted = 'total_missions_completed';
  static const String dailyMissionsCompletedDays = 'daily_missions_days';

  // 리더보드
  static const String leaderboard = 'leaderboard';

  // 온보딩
  static const String isFirstRun = 'is_first_run';
  static const String onboardingStep = 'onboarding_step';
}
