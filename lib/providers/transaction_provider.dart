import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart' as app_models;
import '../models/monthly_budget.dart';
import '../models/profile.dart';
import '../models/budget_alert.dart'; // Add import for BudgetAlert
import '../db/database_helper.dart';
import 'budget_alert_provider.dart';

class TransactionProvider with ChangeNotifier {
  final List<app_models.Transaction> _transactions = [];
  final List<app_models.Category> _categories = [];
  final List<Profile> _profiles = [];
  final List<MonthlyBudget> _budgets = [];
  Profile? _selectedProfile;
  String _currentlyViewedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  List<app_models.Transaction> get transactions =>
      List.unmodifiable(_transactions);
  List<app_models.Category> get categories => List.unmodifiable(_categories);
  List<Profile> get profiles => _profiles;
  MonthlyBudget? get currentBudget =>
      _budgets.isNotEmpty ? _budgets.first : null;
  Profile? get selectedProfile => _selectedProfile;

  Future<void> loadProfiles() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('profiles');

    _profiles.clear();
    if (maps.isEmpty) {
      final now = DateTime.now();
      final id = await db.insert('profiles', {
        'name': 'Profile 1',
        'is_selected': 1,
        'icon_name': 'person',
        'created_at': now.toIso8601String(),
      });

      _profiles.add(Profile(
        id: id,
        name: 'Profile 1',
        iconName: 'person',
        createdAt: now,
        isSelected: true,
      ));
      _selectedProfile = _profiles.first;
    } else {
      _profiles.addAll(maps.map((map) => Profile.fromMap(map)));

      _selectedProfile = _profiles.firstWhere(
        (p) => p.isSelected,
        orElse: () {
          final firstProfile = _profiles.first;
          db.update(
            'profiles',
            {'is_selected': 1},
            where: 'id = ?',
            whereArgs: [firstProfile.id],
          );
          return firstProfile.copyWith(isSelected: true);
        },
      );
    }

    notifyListeners();
  }

  Future<void> addProfile(String name, {String? iconName}) async {
    if (_profiles.length >= 5) {
      throw Exception('Maximum 5 profiles allowed');
    }

    final db = await _dbHelper.database;
    final now = DateTime.now();

    final id = await db.insert('profiles', {
      'name': name,
      'is_selected': 0,
      'icon_name': iconName ?? 'person',
      'created_at': now.toIso8601String(),
    });

    _profiles.add(Profile(
      id: id,
      name: name,
      iconName: iconName ?? 'person',
      createdAt: now,
      isSelected: false,
    ));
    notifyListeners();
  }

  Future<void> switchProfile(int profileId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('profiles', {'is_selected': 0});
      await txn.update(
        'profiles',
        {'is_selected': 1},
        where: 'id = ?',
        whereArgs: [profileId],
      );
    });

    for (var profile in _profiles) {
      final isSelected = profile.id == profileId;
      final index = _profiles.indexOf(profile);
      _profiles[index] = profile.copyWith(isSelected: isSelected);
      if (isSelected) _selectedProfile = _profiles[index];
    }

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    await loadTransactions(currentMonth);
    await loadCurrentBudget(currentMonth);
    notifyListeners();
  }

  Future<void> deleteProfile(int profileId) async {
    if (_profiles.length <= 1) {
      throw Exception('Cannot delete the last profile');
    }
    if (_selectedProfile?.id == profileId) {
      throw Exception('Cannot delete the active profile');
    }

    final db = await _dbHelper.database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
    _profiles.removeWhere((p) => p.id == profileId);
    notifyListeners();
  }

  Future<void> loadTransactions(String month) async {
    if (_selectedProfile == null) await loadProfiles();
    _currentlyViewedMonth = month;

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "date LIKE ? AND profile_id = ?",
      whereArgs: ['$month%', _selectedProfile!.id],
    );

    _transactions.clear();
    _transactions.addAll(
      maps.map((map) => app_models.Transaction.fromMap(map)),
    );
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');

    _categories.clear();
    _categories.addAll(maps.map((map) => app_models.Category.fromMap(map)));
    notifyListeners();
  }

  Future<void> loadCurrentBudget(String month) async {
    if (_selectedProfile == null) await loadProfiles();

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_budgets',
      where: "month = ? AND profile_id = ?",
      whereArgs: [month, _selectedProfile!.id],
      limit: 1,
    );

    _budgets.clear();
    if (maps.isNotEmpty) {
      _budgets.add(MonthlyBudget.fromMap(maps.first));
    }
    notifyListeners();
  }

  Future<void> addTransaction(app_models.Transaction transaction) async {
    final profile = _selectedProfile;
    if (profile?.id == null) {
      throw Exception('No profile selected');
    }

    final db = await _dbHelper.database;
    final id = await db.insert('transactions', transaction.toMap());

    final transactionMonth = DateFormat('yyyy-MM').format(transaction.date);
    if (transactionMonth == _currentlyViewedMonth) {
      _transactions.add(
        app_models.Transaction.fromMap({...transaction.toMap(), 'id': id}),
      );
    }

    // Handle recurring transactions
    if (transaction.isRecurring && transaction.recurrenceFrequency != null) {
      await _createRecurringTransactions(
        app_models.Transaction(
            id: id,
            amount: transaction.amount,
            type: transaction.type,
            categoryId: transaction.categoryId,
            description: transaction.description,
            date: transaction.date,
            profileId: transaction.profileId,
            isRecurring: transaction.isRecurring,
            recurrenceFrequency: transaction.recurrenceFrequency,
            recurrenceEndDate: transaction.recurrenceEndDate),
      );
    }

    // Check budget alerts
    if (transaction.type == 'expense' && _context != null) {
      final month = DateFormat('yyyy-MM').format(transaction.date);
      final budget = currentBudget?.amount ?? 0;

      // Get total expenses for overall budget alert
      final totalExpenses = getTotalExpenses(month);

      // Get category expenses for category budget alert
      final categoryExpenses = _getCategoryExpensesForMonth(
        transaction.categoryId,
        month,
      );

      // Get the alert provider through the BuildContext
      final alertProvider =
          Provider.of<BudgetAlertProvider>(_context!, listen: false);

      // Check category budget alerts
      await alertProvider.checkAlerts(
        transaction.categoryId,
        categoryExpenses,
        budget,
      );

      // Check overall budget alerts (pass null for categoryId to indicate overall budget)
      await alertProvider.checkAlerts(
        null,
        totalExpenses,
        budget,
      );
    }

    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  double _getCategoryExpensesForMonth(int categoryId, String month) {
    return _transactions
        .where((tx) =>
            tx.categoryId == categoryId &&
            tx.type == 'expense' &&
            DateFormat('yyyy-MM').format(tx.date) == month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<void> addCategory(app_models.Category category) async {
    final db = await _dbHelper.database;
    final id = await db.insert('categories', category.toMap());
    _categories.add(
      app_models.Category.fromMap({...category.toMap(), 'id': id}),
    );
    notifyListeners();
  }

  Future<void> setBudget(MonthlyBudget budget) async {
    final profile = _selectedProfile;
    if (profile == null || profile.id == null) {
      throw Exception('No profile selected');
    }

    final db = await _dbHelper.database;

    // Check if a budget already exists for this month
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_budgets',
      where: 'month = ? AND profile_id = ?',
      whereArgs: [budget.month, profile.id],
    );

    if (maps.isNotEmpty) {
      final id = maps.first['id'];
      await db.update(
        'monthly_budgets',
        {
          'amount': budget.amount,
          'is_recurring': budget.isRecurring ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      final updatedBudget = budget.copyWith(
        id: id,
        profileId: profile.id,
      );

      if (_budgets.isNotEmpty) {
        _budgets[0] = updatedBudget;
      } else {
        _budgets.add(updatedBudget);
      }

      // If recurring is enabled, set the same budget for future months (up to 6 months ahead)
      if (budget.isRecurring) {
        await _setRecurringBudgets(budget);
      }
    } else {
      final budgetWithProfile = budget.copyWith(profileId: profile.id);
      final id = await db.insert('monthly_budgets', budgetWithProfile.toMap());
      final newBudget = budgetWithProfile.copyWith(id: id);

      if (_budgets.isNotEmpty) {
        _budgets[0] = newBudget;
      } else {
        _budgets.add(newBudget);
      }

      // If recurring is enabled, set the same budget for future months
      if (budget.isRecurring) {
        await _setRecurringBudgets(budget);
      }
    }

    // Set or update default overall budget alert at 90%
    if (_context != null) {
      final alertProvider =
          Provider.of<BudgetAlertProvider>(_context!, listen: false);
      final alerts = alertProvider.alerts;
      final overallAlert =
          alerts.where((alert) => alert.categoryId == null).firstOrNull;

      if (overallAlert == null) {
        await alertProvider.addAlert(BudgetAlert(
          categoryId: null,
          threshold: 90,
          isPercentage: true,
          enabled: true,
        ));
      }
    }

    notifyListeners();
  }

  Future<void> _setRecurringBudgets(MonthlyBudget budget) async {
    final db = await _dbHelper.database;
    final currentDate = DateTime.parse('${budget.month}-01');

    // Set budgets for next 6 months
    for (int i = 1; i <= 6; i++) {
      final futureDate = DateTime(currentDate.year, currentDate.month + i);
      final futureMonth =
          '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}';

      // Check if budget already exists for this month
      final existing = await db.query(
        'monthly_budgets',
        where: 'month = ? AND profile_id = ?',
        whereArgs: [futureMonth, budget.profileId],
      );

      if (existing.isEmpty) {
        // Create new budget for future month
        final futureBudget = budget.copyWith(
          month: futureMonth,
          isRecurring: true,
        );
        await db.insert('monthly_budgets', futureBudget.toMap());
        print(
            'Created recurring budget for: $futureMonth with amount: ${budget.amount}');
      } else {
        // Update existing budget for future month
        await db.update(
          'monthly_budgets',
          {
            'amount': budget.amount,
            'is_recurring': 1,
          },
          where: 'month = ? AND profile_id = ?',
          whereArgs: [futureMonth, budget.profileId],
        );
        print(
            'Updated recurring budget for: $futureMonth with amount: ${budget.amount}');
      }
    }
  }

  double getTotalExpenses(String month) {
    return _transactions
        .where(
          (t) => t.type == 'expense' && t.date.toString().startsWith(month),
        )
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalIncome(String month) {
    return _transactions
        .where((t) => t.type == 'income' && t.date.toString().startsWith(month))
        .fold(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getExpensesByCategory(String month) {
    final expensesByCategory = <String, double>{};

    for (final transaction in _transactions) {
      if (transaction.type == 'expense' &&
          transaction.date.toString().startsWith(month)) {
        final category = _categories.firstWhere(
          (c) => c.id == transaction.categoryId,
          orElse: () => app_models.Category(name: 'Unknown', type: ''),
        );
        expensesByCategory[category.name] =
            (expensesByCategory[category.name] ?? 0) + transaction.amount;
      }
    }

    return expensesByCategory;
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<bool> canDeleteCategory(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isEmpty;
  }

  Future<List<app_models.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "date BETWEEN ? AND ?",
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
  }

  Future<void> exportTransactions(DateTime startDate, DateTime endDate) async {
    try {
      final csvContent = await _dbHelper.exportToCSV(startDate, endDate);

      final fileName =
          'transactions_${DateFormat('yyyy_MM').format(startDate)}.csv';
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csvContent);

      await Share.shareFiles(
        [tempFile.path],
        mimeTypes: ['text/csv'],
        subject: 'Budget Tracker Transactions',
      );

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      throw Exception('Failed to share transactions: $e');
    }
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await _dbHelper.database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );

    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile;
      if (profile.isSelected) {
        _selectedProfile = profile;
      }
      notifyListeners();
    }
  }

  Future<void> createProfile(Profile profile) async {
    if (_profiles.length >= 5) {
      throw Exception('Maximum 5 profiles allowed');
    }

    final db = await _dbHelper.database;

    final shouldSelect = profile.isSelected || _profiles.isEmpty;

    if (shouldSelect) {
      await db.update('profiles', {'is_selected': 0});
    }

    final id = await db.insert('profiles', {
      'name': profile.name,
      'icon_name': profile.iconName,
      'created_at': profile.createdAt.toIso8601String(),
      'is_selected': shouldSelect ? 1 : 0,
    });

    final newProfile = Profile(
      id: id,
      name: profile.name,
      iconName: profile.iconName,
      createdAt: profile.createdAt,
      isSelected: shouldSelect,
    );

    if (shouldSelect) {
      for (var i = 0; i < _profiles.length; i++) {
        _profiles[i] = _profiles[i].copyWith(isSelected: false);
      }
    }

    _profiles.add(newProfile);
    if (shouldSelect) {
      _selectedProfile = newProfile;
    }

    notifyListeners();
  }

  Future<void> _createRecurringTransactions(
      app_models.Transaction transaction) async {
    if (!transaction.isRecurring || transaction.recurrenceFrequency == null) {
      return;
    }

    final db = await _dbHelper.database;
    DateTime nextDate = _getNextRecurrenceDate(
        transaction.date, transaction.recurrenceFrequency!);

    // Generate recurring transactions up to end date or 1 year ahead if no end date
    final DateTime endDate = transaction.recurrenceEndDate ??
        DateTime.now().add(const Duration(days: 365));

    // Maximum 100 recurring instances to prevent excessive generation
    int maxInstances = 100;

    while (nextDate.isBefore(endDate) && maxInstances > 0) {
      final recurringTransaction = app_models.Transaction(
        amount: transaction.amount,
        type: transaction.type,
        categoryId: transaction.categoryId,
        description: transaction.description,
        date: nextDate,
        profileId: transaction.profileId,
        isRecurring:
            false, // Only the parent transaction is marked as recurring
        recurrenceFrequency: null,
        recurrenceEndDate: null,
      );

      await db.insert('transactions', recurringTransaction.toMap());

      // Move to the next recurrence date
      nextDate =
          _getNextRecurrenceDate(nextDate, transaction.recurrenceFrequency!);
      maxInstances--;
    }
  }

  DateTime _getNextRecurrenceDate(DateTime currentDate, String frequency) {
    switch (frequency) {
      case 'daily':
        return currentDate.add(const Duration(days: 1));
      case 'weekly':
        return currentDate.add(const Duration(days: 7));
      case 'monthly':
        // Add 1 month while handling month length differences
        final nextMonth = DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day >
                  DateTime(currentDate.year, currentDate.month + 2, 0).day
              ? DateTime(currentDate.year, currentDate.month + 2, 0).day
              : currentDate.day,
        );
        return nextMonth;
      case 'yearly':
        // Add 1 year while handling leap years
        final nextYear = DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.month == 2 && currentDate.day == 29
              ? 28 // Handle leap year
              : currentDate.day,
        );
        return nextYear;
      default:
        return currentDate.add(const Duration(days: 30)); // Default to monthly
    }
  }
}
