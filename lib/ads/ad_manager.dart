import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob manager.
/// Call [initialize] once at app start, then use [showInterstitialIfReady]
/// and [showRewarded] from screens.
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  // ── Ad Unit IDs ──────────────────────────────────────────────────────────
  static const String _rewardedId =
      'ca-app-pub-5381891295736795/4954206791'; // 보상형 전면(짧은) - 닫기 버튼 5초 후 표시
  static const String _bannerId =
      'ca-app-pub-5381891295736795/5820749682';
  static const String _interstitialId =
      'ca-app-pub-5381891295736795/8783988206';
  static const String _skinRewardedId =
      'ca-app-pub-5381891295736795/4954206791'; // 보상형 전면(짧은)

  RewardedInterstitialAd? _rewarded;
  RewardedInterstitialAd? _skinRewarded;
  InterstitialAd? _interstitial;
  int _playCount = 0;

  bool get isRewardedReady => _rewarded != null;
  bool get isSkinRewardedReady => _skinRewarded != null;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    _loadRewarded();
    _loadSkinRewarded();
    // _loadInterstitial(); // 전면 광고 비활성화
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────

  void _loadRewarded() {
    if (kIsWeb) return;
    RewardedInterstitialAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] Rewarded load failed: $error');
          _rewarded = null;
        },
      ),
    );
  }

  void _loadSkinRewarded() {
    if (kIsWeb) return;
    RewardedInterstitialAd.load(
      adUnitId: _skinRewardedId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _skinRewarded = ad,
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] Skin rewarded interstitial load failed: $error');
          _skinRewarded = null;
        },
      ),
    );
  }

  /// Shows the skin unlock rewarded interstitial ad.
  /// onRewarded is called only when the user earns the reward (watched enough of the ad).
  void showSkinRewarded({
    required VoidCallback onRewarded,
    required VoidCallback onDone,
  }) {
    if (kIsWeb || _skinRewarded == null) {
      onRewarded(); // 웹/테스트: 광고 없이 즉시 지급
      onDone();
      return;
    }
    final ad = _skinRewarded!;
    _skinRewarded = null;
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadSkinRewarded();
        if (earned) onRewarded();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        debugPrint('[AdManager] Skin rewarded interstitial show failed: $error');
        a.dispose();
        _loadSkinRewarded();
        onDone();
      },
    );

    // onUserEarnedReward: 사용자가 광고를 최소 시청 시간(약 5초) 이상 보거나
    // 끝까지 시청했을 때 호출됨 → 이때만 보상 지급
    ad.show(onUserEarnedReward: (_, rewardItem) {
      earned = true;
    });
  }

  /// Shows the rewarded interstitial ad for game revival.
  /// onRewarded is called only when the user earns the reward (watched ~5s or more).
  /// Close button appears natively after ~5 seconds.
  void showRewarded({
    required VoidCallback onRewarded,
    required VoidCallback onDone,
  }) {
    if (kIsWeb || _rewarded == null) {
      onDone();
      return;
    }
    final ad = _rewarded!;
    _rewarded = null;
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (earned) onRewarded();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        debugPrint('[AdManager] Rewarded show failed: $error');
        a.dispose();
        _loadRewarded();
        onDone();
      },
    );

    ad.show(onUserEarnedReward: (_, __) => earned = true);
  }

  // ── Interstitial (비활성화) ───────────────────────────────────────────────

  // void _loadInterstitial() {
  //   if (kIsWeb) return;
  //   InterstitialAd.load(
  //     adUnitId: _interstitialId,
  //     request: const AdRequest(),
  //     adLoadCallback: InterstitialAdLoadCallback(
  //       onAdLoaded: (ad) => _interstitial = ad,
  //       onAdFailedToLoad: (error) {
  //         debugPrint('[AdManager] Interstitial load failed: $error');
  //         _interstitial = null;
  //       },
  //     ),
  //   );
  // }

  /// 전면 광고 비활성화 — 재활성화 시 _loadInterstitial() 주석 해제 후 initialize()에서 호출
  void showInterstitialIfReady({required VoidCallback onDone}) {
    onDone();
  }

  // ── Banner ────────────────────────────────────────────────────────────────

  /// Creates and loads a new BannerAd. Caller is responsible for disposal.
  BannerAd createBanner({required BannerAdListener listener}) {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    )..load();
  }
}
