import 'package:flutter/material.dart';
import '../economy/persistence_manager.dart';

/// 연속 플랫폼 착지 콤보 & 점수 배율 관리
class ComboManager extends ChangeNotifier {
  int _combo = 0;
  int _maxComboThisSession = 0;

  int get combo => _combo;
  double get multiplier => _calcMultiplier(_combo);
  bool get isCoinDouble => _combo >= 20;

  double _calcMultiplier(int c) {
    if (c >= 20) return 2.0;
    if (c >= 10) return 1.5;
    if (c >= 5) return 1.2;
    return 1.0;
  }

  /// 플랫폼 착지 성공 시 호출
  void onLand() {
    _combo++;
    if (_combo > _maxComboThisSession) _maxComboThisSession = _combo;
    notifyListeners();
  }

  /// 착지 실패 또는 낙사 시 호출
  void onBreak() {
    _combo = 0;
    notifyListeners();
  }

  void reset() {
    _combo = 0;
    _maxComboThisSession = 0;
  }

  /// 세션 종료 후 최대 콤보 기록 저장
  Future<void> commitSession() async {
    final pm = PersistenceManager.instance;
    if (_maxComboThisSession > pm.statMaxCombo) {
      await pm.setStatMaxCombo(_maxComboThisSession);
    }
  }

  int get maxComboThisSession => _maxComboThisSession;

  /// 현재 콤보 단계 레이블 (UI 표시용)
  String get comboLabel {
    if (_combo >= 20) return 'FEVER! x2.0';
    if (_combo >= 10) return 'HOT! x1.5';
    if (_combo >= 5) return 'COMBO x1.2';
    return '';
  }

  /// 콤보 색상
  Color get comboColor {
    if (_combo >= 20) return const Color(0xFFFF6D00);
    if (_combo >= 10) return const Color(0xFFFFD600);
    if (_combo >= 5) return const Color(0xFF69FF47);
    return Colors.white;
  }
}
