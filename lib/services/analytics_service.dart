import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Feature usage events - these help identify which features to highlight in store listing
  static const String EVENT_VIEW_DASHBOARD = 'view_dashboard';
  static const String EVENT_ADD_EXPENSE = 'add_expense';
  static const String EVENT_ADD_INCOME = 'add_income';
  static const String EVENT_VIEW_REPORTS = 'view_reports';
  static const String EVENT_CREATE_BUDGET = 'create_budget';
  static const String EVENT_SHARE_REPORT = 'share_report';
  static const String EVENT_EXPORT_DATA = 'export_data';
  static const String EVENT_PROFILE_SWITCH = 'profile_switch';

  static Future<void> logEvent(String name,
      {Map<String, dynamic>? parameters}) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  // Track search terms used within the app to identify popular user interests
  static Future<void> logSearch(String searchTerm) async {
    await analytics.logSearch(searchTerm: searchTerm);
  }

  // Track feature engagement (helps prioritize features in store listing)
  static Future<void> logFeatureUse(String featureName,
      {Map<String, dynamic>? details}) async {
    await logEvent('feature_use',
        parameters: {'feature_name': featureName, ...?details});
  }

  // Track user engagement duration with specific features
  static Future<void> logFeatureEngagementTime(
      String featureName, int durationSeconds) async {
    await logEvent('feature_engagement_time', parameters: {
      'feature_name': featureName,
      'duration_seconds': durationSeconds
    });
  }

  // Track app shares - important for viral growth
  static Future<void> logAppShare() async {
    await analytics.logShare(
        contentType: 'app',
        itemId: 'com.fincalculators.moneytrack',
        method: 'generic');
  }
}
