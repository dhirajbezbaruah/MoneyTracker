import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deep_link_service.dart';

/// Service to manage app rating prompts
/// Strategically asking users for ratings improves app store ranking
class AppRatingService {
  static final AppRatingService _instance = AppRatingService._internal();
  final DeepLinkService _deepLinkService = DeepLinkService();

  // Constants
  static const String _prefsLastRatingPrompt = 'last_rating_prompt';
  static const String _prefsAppOpenCount = 'app_open_count';
  static const String _prefsHasRated = 'has_rated_app';
  static const int _promptThreshold = 5; // Show after 5 uses

  factory AppRatingService() => _instance;

  AppRatingService._internal();

  /// Initialize the rating service
  Future<void> initialize() async {
    await trackAppOpen();
  }

  /// Track app open to determine when to show rating prompt
  Future<void> trackAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final int currentCount = prefs.getInt(_prefsAppOpenCount) ?? 0;
    await prefs.setInt(_prefsAppOpenCount, currentCount + 1);
  }

  /// Check if we should show the rating prompt
  Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    // If user has already rated, don't show again
    if (prefs.getBool(_prefsHasRated) == true) {
      return false;
    }

    // Check usage count
    final int openCount = prefs.getInt(_prefsAppOpenCount) ?? 0;
    if (openCount < _promptThreshold) {
      return false;
    }

    // Check when we last asked
    final int lastPrompt = prefs.getInt(_prefsLastRatingPrompt) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;
    // Don't ask more than once every 14 days
    if (now - lastPrompt < const Duration(days: 14).inMilliseconds &&
        lastPrompt != 0) {
      return false;
    }

    return true;
  }

  /// Show the rating dialog
  Future<void> showRatingDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Only proceed if we should show the dialog
    if (!await shouldShowRatingPrompt()) {
      return;
    }

    // Update last prompt time
    await prefs.setInt(
        _prefsLastRatingPrompt, DateTime.now().millisecondsSinceEpoch);

    // Show the dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enjoying Budget Tracker?'),
          content: const Text(
              'If you find Budget Tracker helpful for managing your finances, please consider rating it in the Play Store. Your feedback helps us improve!'),
          actions: [
            TextButton(
              child: const Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Never Ask'),
              onPressed: () async {
                await prefs.setBool(_prefsHasRated, true);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Rate App'),
              onPressed: () async {
                await prefs.setBool(_prefsHasRated, true);
                await _deepLinkService.openAppStorePage();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }
}
