import 'package:flutter/material.dart';
import '../models/budget_alert.dart';
import '../db/database_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BudgetAlertProvider with ChangeNotifier {
  final List<BudgetAlert> _alerts = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<BudgetAlert> get alerts => List.unmodifiable(_alerts);

  Future<void> loadAlerts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('budget_alerts');

    _alerts.clear();
    _alerts.addAll(maps.map((map) => BudgetAlert.fromMap(map)));
    notifyListeners();
  }

  Future<void> addAlert(BudgetAlert alert) async {
    final db = await _dbHelper.database;
    final id = await db.insert('budget_alerts', alert.toMap());
    _alerts.add(BudgetAlert.fromMap({...alert.toMap(), 'id': id}));
    notifyListeners();
  }

  Future<void> updateAlert(BudgetAlert alert) async {
    if (alert.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      'budget_alerts',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );

    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      _alerts[index] = alert;
      notifyListeners();
    }
  }

  Future<void> deleteAlert(int id) async {
    final db = await _dbHelper.database;
    await db.delete('budget_alerts', where: 'id = ?', whereArgs: [id]);
    _alerts.removeWhere((alert) => alert.id == id);
    notifyListeners();
  }

  Future<void> checkAlerts(
      int? categoryId, double currentSpent, double budget) async {
    if (budget <= 0) return; // Don't check alerts if there's no budget set

    final relevantAlerts = _alerts
        .where((alert) => alert.enabled && alert.categoryId == categoryId);

    if (categoryId != null) {
      // Category-specific budget alert
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> categoryMaps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );

      if (categoryMaps.isEmpty) return;
      final categoryName = categoryMaps.first['name'] as String;

      for (final alert in relevantAlerts) {
        final threshold = alert.isPercentage
            ? budget * (alert.threshold / 100)
            : alert.threshold;

        if (currentSpent >= threshold) {
          await _showNotification(
            'Budget Alert 💰',
            alert.isPercentage
                ? '$categoryName: You have spent ${(currentSpent / budget * 100).toStringAsFixed(1)}% of your budget'
                : '$categoryName: You have spent \$${currentSpent.toStringAsFixed(0)} of your budget',
          );
        }
      }
    } else {
      // Overall budget alert
      for (final alert in relevantAlerts) {
        final threshold = alert.isPercentage
            ? budget * (alert.threshold / 100)
            : alert.threshold;

        if (currentSpent >= threshold) {
          await _showNotification(
            'Budget Alert 💵',
            alert.isPercentage
                ? 'Total spending has reached ${(currentSpent / budget * 100).toStringAsFixed(1)}% of your monthly budget'
                : 'Total spending has reached \$${currentSpent.toStringAsFixed(0)} of your monthly budget',
          );
        }
      }
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alerts_channel', // Match the channel ID we created in main.dart
      'Budget Alerts',
      channelDescription: 'Notifications for budget alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }
}
