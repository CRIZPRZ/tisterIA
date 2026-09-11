import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad unit real de AdMob (Rewarded, Android) — cuenta en revisión: no
/// mostrará anuncios reales hasta que AdMob apruebe la app y la unidad
/// (puede tardar hasta ~1h desde su creación, o más si la app sigue en
/// revisión).
const _kRewardedAdUnitId = 'ca-app-pub-2698512492994710/7918829481';

class AdsService {
  AdsService._internal();
  static final AdsService instance = AdsService._internal();

  bool _initialized = false;
  RewardedAd? _ad;

  Future<void> init() async {
    if (_initialized || !Platform.isAndroid) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _preload();
  }

  void _preload() {
    RewardedAd.load(
      adUnitId: _kRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (_) => _ad = null,
      ),
    );
  }

  bool get isReady => Platform.isAndroid && _ad != null;

  /// Muestra el rewarded ad. Llama [onRewarded] solo si el usuario lo vio
  /// completo (el SDK ya validó eso). Siempre precarga el siguiente al cerrar.
  Future<void> show({required void Function() onRewarded, void Function()? onUnavailable}) async {
    final ad = _ad;
    if (ad == null) {
      onUnavailable?.call();
      _preload();
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _preload();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _preload();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => onRewarded());
  }
}
