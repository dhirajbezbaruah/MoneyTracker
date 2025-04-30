import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to handle deep linking and app sharing functionality
/// This improves app discoverability and SEO ranking in the Play Store
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();

  factory DeepLinkService() => _instance;

  DeepLinkService._internal();

  /// Initialize deep link handling
  Future<void> initialize() async {
    // Configure Firebase Messaging for deep links
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.containsKey('deepLink')) {
        _handleDeepLink(message.data['deepLink']);
      }
    });
  }

  /// Handle incoming deep links
  void _handleDeepLink(String link) {
    // Process deep link logic
    debugPrint('Deep link received: $link');
  }

  /// Share app with customized message that includes keywords for better discoverability
  Future<void> shareApp() async {
    const String appLink =
        'https://play.google.com/store/apps/details?id=com.fincalculators.moneytrack';
    const String message =
        'Check out Budget Tracker: Budget & Expense Manager - the perfect app for tracking expenses, managing budgets and monitoring your finances! $appLink';

    await Share.share(message,
        subject: 'Track Your Finances with Budget Tracker App');
  }

  /// Open app store page (useful for ratings)
  Future<void> openAppStorePage() async {
    const String appLink =
        'https://play.google.com/store/apps/details?id=com.fincalculators.moneytrack';
    final Uri url = Uri.parse(appLink);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// Generate a dynamic sharing link with category information
  /// This helps with search indexing of specific app features
  String generateFeatureLink(String feature) {
    return 'https://moneytrack.fincalculators.com/features/$feature';
  }
}
