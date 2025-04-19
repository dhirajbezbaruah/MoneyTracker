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
  bool _isOffline = false;
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
        setState(() {
          _isOffline = true;
        });
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
            _isOffline = false;
          });
          _loadingTimer?.cancel();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
          if (mounted) {
            setState(() {
              _isOffline = true;
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

    // Return a minimal placeholder when offline or failed to load
    if (_isOffline) {
      return Container(
        height: 50,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade200,
        child: Center(
          child: Text(
            'Ad not available',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    // Return a loading placeholder when still trying to load
    return SizedBox(
      height: 50,
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
