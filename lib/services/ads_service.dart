import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService extends ChangeNotifier {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  static const List<String> _testDeviceIds = [
    'F03AAD55718061D1AA01024CE7B58141',
  ];

  static String get bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : Platform.isAndroid
          ? 'ca-app-pub-6305842101129705/7701450136'
          : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : Platform.isAndroid
          ? 'ca-app-pub-6305842101129705/9553587852'
          : 'ca-app-pub-3940256099942544/4411468910';

  static String get rewardedAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : Platform.isAndroid
          ? 'ca-app-pub-6305842101129705/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: _testDeviceIds),
    );
    developer.log('AdsService initialized');
    loadInterstitialAd();
    loadRewardedAd();
  }

  // Banner Ad
  void loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          developer.log('Banner ad loaded successfully');
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerLoaded = false;
          developer.log('Banner ad failed to load: $error');
          notifyListeners();
        },
      ),
    )..load();
    developer.log('Banner ad load initiated');
  }

  BannerAd? get bannerAd => _isBannerLoaded ? _bannerAd : null;

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
    developer.log('Banner ad disposed');
    notifyListeners();
  }

  // Interstitial Ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          developer.log('Interstitial ad loaded successfully');
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoaded = false;
          developer.log('Interstitial ad failed to load: $error');
          notifyListeners();
        },
      ),
    );
    developer.log('Interstitial ad load initiated');
  }

  Future<void> showInterstitialAd() async {
    if (_isInterstitialLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialLoaded = false;
      // Carregar próximo anúncio
      loadInterstitialAd();
      developer.log('Interstitial ad shown');
    } else {
      developer.log('Interstitial ad not ready to show');
    }
  }

  // Rewarded Ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          developer.log('Rewarded ad loaded successfully');
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoaded = false;
          developer.log('Rewarded ad failed to load: $error');
          notifyListeners();
        },
      ),
    );
    developer.log('Rewarded ad load initiated');
  }

  Future<void> showRewardedAd({
    required Function onUserEarnedReward,
  }) async {
    if (_isRewardedLoaded && _rewardedAd != null) {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward();
        },
      );
      _rewardedAd = null;
      _isRewardedLoaded = false;
      // Carregar próximo anúncio
      loadRewardedAd();
      developer.log('Rewarded ad shown');
    } else {
      developer.log('Rewarded ad not ready to show');
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    developer.log('All ads disposed');
    notifyListeners();
    super.dispose();
  }
}
