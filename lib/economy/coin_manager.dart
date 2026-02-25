import 'package:flutter/material.dart';
import 'persistence_manager.dart';

/// 코인 잔액 관리 + 인게임 세션 수급 처리
class CoinManager extends ChangeNotifier {
  final PersistenceManager _pm = PersistenceManager.instance;

  int _balance = 0;
  int _sessionCoins = 0; // 현재 게임에서 획득한 코인
  int _sessionPlatforms = 0; // 이번 게임 착지 플랫폼 수 (점수 보너스 계산용)
  bool _doubleCoinsActive = false; // 2배 코인 부스터

  int get balance => _balance;
  int get sessionCoins => _sessionCoins;

  Future<void> init() async {
    await _pm.init();
    _balance = _pm.coins;
  }

  // ── 세션 초기화 ────────────────────────────────────────────────────────────
  void resetSession() {
    _sessionCoins = 0;
    _sessionPlatforms = 0;
  }

  // ── 인게임 수급 ───────────────────────────────────────────────────────────

  /// 플랫폼 착지 시 호출 (gravityPad: +3, 일반: +1)
  void onPlatformLand({bool isGravityPad = false}) {
    _sessionPlatforms++;
    final base = isGravityPad ? 3 : 1;
    _addSession(base);

    // 100 착지마다 +5 보너스
    if (_sessionPlatforms % 100 == 0) {
      _addSession(5);
    }
  }

  /// 점수 100點 단위 보너스 코인 (+5)
  void onScoreMilestone() {
    _addSession(5);
  }

  void _addSession(int amount) {
    final actual = _doubleCoinsActive ? amount * 2 : amount;
    _sessionCoins += actual;
    notifyListeners();
  }

  // ── 세션 종료 후 잔액 반영 ─────────────────────────────────────────────────
  Future<void> commitSession() async {
    _balance += _sessionCoins;
    await _pm.setCoins(_balance);
    await _pm.addStatTotalCoinsEver(_sessionCoins);
    notifyListeners();
  }

  // ── 소비 ──────────────────────────────────────────────────────────────────

  /// 코인 소비. 잔액 부족 시 false 반환.
  Future<bool> spend(int amount) async {
    if (_balance < amount) return false;
    _balance -= amount;
    await _pm.setCoins(_balance);
    notifyListeners();
    return true;
  }

  /// 부활 (30코인)
  Future<bool> buyRevive() => spend(30);

  /// 2배 코인 1판 부스터 (50코인)
  Future<bool> buyDoubleCoins() async {
    final ok = await spend(50);
    if (ok) _doubleCoinsActive = true;
    return ok;
  }

  void clearDoubleCoins() {
    _doubleCoinsActive = false;
  }

  bool get isDoubleCoinsActive => _doubleCoinsActive;

  // ── 외부에서 직접 지급 (업적 보상 등) ─────────────────────────────────────
  Future<void> addDirect(int amount) async {
    _balance += amount;
    await _pm.setCoins(_balance);
    await _pm.addStatTotalCoinsEver(amount);
    notifyListeners();
  }
}
