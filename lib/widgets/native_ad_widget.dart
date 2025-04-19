import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({Key? key}) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      // Use your actual ad unit ID
      adUnitId: 'ca-app-pub-1380680048513180/7302560899',

      // For testing, use: 'ca-app-pub-3940256099942544/2247696110'

      // Define ad request
      request: const AdRequest(),

      // Define ad listener
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Native ad failed to load: $error');
        },
      ),

      // Use a standard native ad format
      factoryId: 'adFactoryExample',

      // Define which ad assets to include
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.landscape,
      ),
    );

    _nativeAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _nativeAd != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: _nativeAd!),
        ),
      );
    }

    // Placeholder while loading
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text("Ad is loading..."),
        ),
      ),
    );
  }
}
