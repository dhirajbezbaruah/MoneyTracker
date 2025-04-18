import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart' as app_models;
import '../models/monthly_budget.dart';
import '../models/profile.dart';
import '../db/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  final List<app_models.Transaction> _transactions = [];
  final List<app_models.Category> _categories = [];
  final List<Profile> _profiles = [];
  MonthlyBudget? _currentBudget;
  Profile? _selectedProfile;
  String _currentlyViewedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  List<app_models.Transaction> get transactions => _transactions;
  List<app_models.Category> get categories => _categories;
  List<Profile> get profiles => _profiles;
  MonthlyBudget? get currentBudget => _currentBudget;
  Profile? get selectedProfile => _selectedProfile;

  Future<void> loadProfiles() async {
    print('DEBUG: loadProfiles called');
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('profiles');
    print('DEBUG: profiles from db: ' + maps.toString());

    _profiles.clear();
    if (maps.isEmpty) {
      // Create default profile if no profiles exist
      final id = await db.insert('profiles', {
        'name': 'Profile 1',
        'is_selected': 1,
      });
      _profiles.add(Profile(id: id, name: 'Profile 1', isSelected: true));
      _selectedProfile = _profiles.first;
    } else {
      _profiles.addAll(maps.map((map) => Profile.fromMap(map)));

      // Find the selected profile
      _selectedProfile = _profiles.firstWhere(
        (p) => p.isSelected,
        orElse: () {
          // If no profile is selected, select and update the first one
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

    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('profiles', {
      'name': name,
      'is_selected': 0,
      'icon_name': iconName ?? 'person',
    });
    _profiles.add(Profile(id: id, name: name, iconName: iconName ?? 'person'));
    notifyListeners();
  }

  Future<void> switchProfile(int profileId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Unselect all profiles
      await txn.update('profiles', {'is_selected': 0});
      // Select the new profile
      await txn.update(
        'profiles',
        {'is_selected': 1},
        where: 'id = ?',
        whereArgs: [profileId],
      );
    });

    // Update local state
    for (var profile in _profiles) {
      final isSelected = profile.id == profileId;
      final index = _profiles.indexOf(profile);
      _profiles[index] = profile.copyWith(isSelected: isSelected);
      if (isSelected) _selectedProfile = _profiles[index];
    }

    // Reload data for new profile
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

    final db = await DatabaseHelper.instance.database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
    _profiles.removeWhere((p) => p.id == profileId);
    notifyListeners();
  }

  Future<void> loadTransactions(String month) async {
    if (_selectedProfile == null) await loadProfiles();
    _currentlyViewedMonth = month;

    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: month == currentMonth
          ? "date LIKE ? AND profile_id = ?"
          : "date LIKE ? AND profile_id = ? AND NOT date LIKE ?",
      whereArgs: month == currentMonth
          ? ['$month%', _selectedProfile!.id]
          : ['$month%', _selectedProfile!.id, '$currentMonth%'],
    );

    _transactions.clear();
    _transactions.addAll(
      maps.map((map) => app_models.Transaction.fromMap(map)),
    );
    notifyListeners();
  }

  Future<void> loadCategories() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');

    _categories.clear();
    _categories.addAll(maps.map((map) => app_models.Category.fromMap(map)));
    notifyListeners();
  }

  Future<void> loadCurrentBudget(String month) async {
    if (_selectedProfile == null) await loadProfiles();

    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_budgets',
      where: "month = ? AND profile_id = ?",
      whereArgs: [month, _selectedProfile!.id],
      limit: 1,
    );

    _currentBudget = maps.isEmpty ? null : MonthlyBudget.fromMap(maps.first);
    notifyListeners();
  }

  Future<void> addTransaction(app_models.Transaction transaction) async {
    final profile = _selectedProfile;
    if (profile?.id == null) {
      throw Exception('No profile selected');
    }

    final profileId = profile!.id!;
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('transactions', transaction.toMap());

    // Only add to UI list if transaction month matches currently viewed month
    final transactionMonth = DateFormat('yyyy-MM').format(transaction.date);
    if (transactionMonth == _currentlyViewedMonth) {
      _transactions.add(
        app_models.Transaction.fromMap({...transaction.toMap(), 'id': id}),
      );
    }

    // If this is an income transaction, add it to the current month's budget
    if (transaction.type == 'income') {
      final month = transaction.date.toString().substring(
            0,
            7,
          ); // YYYY-MM format
      final currentBudget = await _getCurrentOrCreateBudget(month);
      await setBudget(
        MonthlyBudget(
          id: currentBudget.id,
          month: month,
          amount: currentBudget.amount + transaction.amount,
          profileId: profileId,
        ),
      );
    }

    notifyListeners();
  }

  Future<MonthlyBudget> _getCurrentOrCreateBudget(String month) async {
    final profile = _selectedProfile;
    if (profile?.id == null) {
      throw Exception('No profile selected');
    }

    final profileId = profile!.id!;
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_budgets',
      where: "month = ? AND profile_id = ?",
      whereArgs: [month, profileId],
      limit: 1,
    );

    if (maps.isEmpty) {
      final budget = MonthlyBudget(
        month: month,
        amount: 0,
        profileId: profileId,
      );
      final id = await db.insert('monthly_budgets', budget.toMap());
      return budget.copyWith(id: id);
    }

    return MonthlyBudget.fromMap(maps.first);
  }

  Future<void> addCategory(app_models.Category category) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('categories', category.toMap());
    _categories.add(
      app_models.Category.fromMap({...category.toMap(), 'id': id}),
    );
    notifyListeners();
  }

  Future<void> setBudget(MonthlyBudget budget) async {
    final profile = _selectedProfile;
    if (profile?.id == null) {
      throw Exception('No profile selected');
    }

    final profileId = profile!.id!;
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_budgets',
      where: 'month = ? AND profile_id = ?',
      whereArgs: [budget.month, profileId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final id = maps.first['id'];
      await db.update(
        'monthly_budgets',
        {'amount': budget.amount},
        where: 'id = ?',
        whereArgs: [id],
      );
      _currentBudget = MonthlyBudget(
        id: id,
        month: budget.month,
        amount: budget.amount,
        profileId: profileId,
      );
    } else {
      final id = await db.insert('monthly_budgets', budget.toMap());
      _currentBudget = MonthlyBudget(
        id: id,
        month: budget.month,
        amount: budget.amount,
        profileId: profileId,
      );
    }
    notifyListeners();
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

  Future<void> deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<bool> canDeleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
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
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "date BETWEEN ? AND ?",
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
  }

  Future<void> exportTransactions(DateTime startDate, DateTime endDate) async {
    try {
      print('TransactionProvider: Calling DatabaseHelper.exportToCSV');
      final csvContent =
          await DatabaseHelper.instance.exportToCSV(startDate, endDate);

      final fileName =
          'transactions_${DateFormat('yyyy_MM').format(startDate)}.csv';
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csvContent);

      await Share.shareFiles(
        [tempFile.path],
        mimeTypes: ['text/csv'],
        subject: 'Money Track Transactions',
      );

      // Clean up the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      print('Export error in exportTransactions: $e');
      throw Exception('Failed to share transactions: $e');
    }
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await DatabaseHelper.instance.database;
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
}
