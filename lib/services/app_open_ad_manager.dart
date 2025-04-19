import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class AppOpenAdManager {
  // Your app open ad unit ID
  static const String adUnitId = 'ca-app-pub-1380680048513180/4554351897';

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isAdLoaded = false;

  // Load timeout
  Timer? _loadingTimer;

  // We don't want to show ads too frequently
  DateTime? _lastAdShownTime;
  static const Duration _minTimeBetweenAds = Duration(minutes: 3);

  /// Loads an AppOpenAd
  void loadAd() {
    if (_appOpenAd != null) return;

    // Set a timer to detect if ad fails to load
    _loadingTimer = Timer(const Duration(seconds: 8), () {
      if (!_isAdLoaded) {
        _appOpenAd = null;
      }
    });

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAdLoaded = true;
          _loadingTimer?.cancel();
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
          _appOpenAd = null;
          _isAdLoaded = false;
          _loadingTimer?.cancel();
        },
      ),
    );
  }

  /// Shows the ad if it's available and enough time has passed since last shown
  bool showAdIfAvailable() {
    if (!_isAdLoaded || _isShowingAd) return false;

    // Don't show too frequently
    if (_lastAdShownTime != null) {
      final DateTime now = DateTime.now();
      if (now.difference(_lastAdShownTime!) < _minTimeBetweenAds) {
        return false;
      }
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _lastAdShownTime = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;

        // Load a new ad for next time
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;

        // Try to load a new ad
        loadAd();
      },
    );

    _appOpenAd!.show();
    _lastAdShownTime = DateTime.now();

    return true;
  }

  /// Clean up resources
  void dispose() {
    _appOpenAd?.dispose();
    _loadingTimer?.cancel();
    _appOpenAd = null;
  }
}
