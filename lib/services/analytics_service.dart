import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Future<void> logEvent(String name,
      {Map<String, dynamic>? parameters}) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }
}
