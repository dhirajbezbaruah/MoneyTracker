import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Timer? _loadingTimer;

  // Your specific banner ad unit ID
  final String adUnitId = 'ca-app-pub-1380680048513180/9680715758';

  @override
  void initState() {
    super.initState();
    _loadAd();

    // Set a timer to detect if ad fails to load
    _loadingTimer = Timer(const Duration(seconds: 8), () {
      if (!_isLoaded && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
          _loadingTimer?.cancel();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
          if (mounted) {
            setState(() {
              // No need to set any flags, just update the UI to show nothing
            });
          }
          _loadingTimer?.cancel();
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Return an empty container when offline or ad not loaded
    // This ensures nothing is displayed when no ad is available
    return const SizedBox.shrink();
  }
}
