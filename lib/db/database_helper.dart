import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart' as app_models;
import 'package:intl/intl.dart';
import 'package:sqflite_common/sqlite_api.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_tracker.db');
    await ensureSchema();
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    Sqflite.setDebugModeOn(true);
    print('Initializing database at path: $path');
    return await openDatabase(
      path,
      version: 7, // Increment version to trigger migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    if (oldVersion < 6) {
      try {
        await db.execute(
            'ALTER TABLE monthly_budgets ADD COLUMN is_recurring INTEGER DEFAULT 0');
        print('Added is_recurring column during upgrade');
      } catch (e) {
        print('Error adding is_recurring column in _onUpgrade: $e');
      }
    }

    // Add recurring transaction columns if upgrading to version 7
    if (oldVersion < 7) {
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN is_recurring INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN recurrence_frequency TEXT');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN recurrence_end_date TEXT');
        print('Added recurring transaction columns during upgrade');
      } catch (e) {
        print('Error adding recurring transaction columns in _onUpgrade: $e');
      }
    }
  }

  Future<void> ensureSchema() async {
    final db = await database;
    print('Checking schema for is_recurring column...');
    try {
      await db.rawQuery('SELECT is_recurring FROM monthly_budgets LIMIT 1');
      print('is_recurring column exists');
    } catch (e) {
      print('is_recurring column missing, attempting to add: $e');
      try {
        await db.execute(
            'ALTER TABLE monthly_budgets ADD COLUMN is_recurring INTEGER DEFAULT 0');
        print('Successfully added is_recurring column');
      } catch (e) {
        print('Failed to add is_recurring column in ensureSchema: $e');
        throw Exception('Cannot add is_recurring column: $e');
      }
    }

    // Check for recurring transaction fields in transactions table
    print('Checking schema for recurring transaction fields...');
    try {
      await db.rawQuery(
          'SELECT is_recurring, recurrence_frequency, recurrence_end_date FROM transactions LIMIT 1');
      print('Recurring transaction fields exist');
    } catch (e) {
      print('Recurring transaction fields missing, attempting to add: $e');
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN is_recurring INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN recurrence_frequency TEXT');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN recurrence_end_date TEXT');
        print('Successfully added recurring transaction fields');
      } catch (e) {
        print('Failed to add recurring transaction fields in ensureSchema: $e');
        throw Exception('Cannot add recurring transaction fields: $e');
      }
    }
  }

  Future<int> getDatabaseVersion() async {
    final db = await database;
    final version = await db.getVersion();
    print('Current database version: $version');
    return version;
  }

  Future<void> checkSchema() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA table_info(monthly_budgets)');
    print('monthly_budgets schema: $result');
  }

  // Helper method to get budget details by ID
  Future<Map<String, dynamic>?> getBudgetById(int id) async {
    final db = await database;
    final result = await db.query(
      'monthly_budgets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Helper method to check if a budget exists for a given month and profile
  Future<Map<String, dynamic>?> getBudgetByMonthAndProfile(
      String month, int profileId) async {
    final db = await database;
    final result = await db.query(
      'monthly_budgets',
      where: 'month = ? AND profile_id = ?',
      whereArgs: [month, profileId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Modified setBudget to handle recurring budgets
  Future<void> setBudget(int id, double amount, bool isRecurring) async {
    final db = await database;
    await ensureSchema();

    // Get the current budget details
    final currentBudget = await getBudgetById(id);
    if (currentBudget == null) {
      throw Exception('Budget with id $id not found');
    }

    final currentMonth = currentBudget['month'] as String;
    final profileId = currentBudget['profile_id'] as int;

    // Update the current budget
    try {
      await db.update(
        'monthly_budgets',
        {
          'amount': amount,
          'is_recurring': isRecurring ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      print(
          'Updated budget: id=$id, month=$currentMonth, amount=$amount, is_recurring=$isRecurring');
    } catch (e) {
      print('Error updating budget: $e');
      rethrow;
    }

    // If recurring, propagate to future months
    if (isRecurring) {
      final dateFormat = DateFormat('yyyy-MM');
      final currentDate = dateFormat.parse(currentMonth);
      const maxFutureMonths =
          12; // Define how many future months to update (e.g., 1 year)

      for (int i = 1; i <= maxFutureMonths; i++) {
        final futureDate = DateTime(currentDate.year, currentDate.month + i);
        final futureMonth = dateFormat.format(futureDate);

        // Check if a budget exists for the future month
        final existingBudget =
            await getBudgetByMonthAndProfile(futureMonth, profileId);

        if (existingBudget != null) {
          // Update existing budget
          try {
            await db.update(
              'monthly_budgets',
              {
                'amount': amount,
                'is_recurring': 1,
              },
              where: 'month = ? AND profile_id = ?',
              whereArgs: [futureMonth, profileId],
            );
            print(
                'Updated recurring budget: month=$futureMonth, amount=$amount');
          } catch (e) {
            print('Error updating recurring budget for $futureMonth: $e');
          }
        } else {
          // Insert new budget
          try {
            await db.insert(
              'monthly_budgets',
              {
                'month': futureMonth,
                'amount': amount,
                'profile_id': profileId,
                'is_recurring': 1,
              },
            );
            print(
                'Inserted recurring budget: month=$futureMonth, amount=$amount');
          } catch (e) {
            print('Error inserting recurring budget for $futureMonth: $e');
          }
        }
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE profiles (
        id $idType,
        name $textType,
        is_selected $integerType DEFAULT 0,
        icon_name TEXT,
        created_at $textType DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.insert('profiles', {
      'name': 'Profile 1',
      'is_selected': 1,
      'icon_name': 'person',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        type $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        amount $realType,
        type $textType,
        category_id $integerType,
        description TEXT,
        date $textType,
        profile_id $integerType,
        is_recurring INTEGER DEFAULT 0,
        recurrence_frequency TEXT,
        recurrence_end_date TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (profile_id) REFERENCES profiles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL,
        amount REAL NOT NULL,
        profile_id INTEGER NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        threshold REAL NOT NULL,
        is_percentage INTEGER NOT NULL DEFAULT 0,
        enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    final batch = db.batch();
    batch.insert('categories', {'name': 'Groceries', 'type': 'expense'});
    batch.insert('categories', {'name': 'Transport', 'type': 'expense'});
    batch.insert('categories', {'name': 'Entertainment', 'type': 'expense'});
    batch.insert('categories', {'name': 'General', 'type': 'expense'});
    batch.insert('categories', {'name': 'Medical', 'type': 'expense'});
    batch.insert('categories', {'name': 'Food', 'type': 'expense'});
    batch.insert('categories', {'name': 'Salary', 'type': 'income'});
    batch.insert('categories', {'name': 'Gift', 'type': 'income'});
    batch.insert('categories', {'name': 'Receivable', 'type': 'income'});
    await batch.commit();
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'money_tracker.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    if (await databaseExists(path)) {
      await deleteDatabase(path);
    }
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'money_tracker.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    if (await databaseExists(path)) {
      await databaseFactory.deleteDatabase(path);
    }

    await database;
  }

  Future<List<app_models.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "date BETWEEN ? AND ?",
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
  }

  Future<List<app_models.Transaction>> getTransactionsByMonth(
    String month,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: ['$month%'],
    );

    return maps.map((map) => app_models.Transaction.fromMap(map)).toList();
  }

  Future<List<app_models.Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');

    return maps.map((map) => app_models.Category.fromMap(map)).toList();
  }

  Future<List<app_models.Category>> getCategoriesByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
    );

    return maps.map((map) => app_models.Category.fromMap(map)).toList();
  }

  Future<app_models.Category?> getCategoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return app_models.Category.fromMap(maps.first);
  }

  Future<String> exportToCSV(DateTime startDate, DateTime endDate) async {
    try {
      final db = await database;
      print('Querying transactions from database...');
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: "date BETWEEN ? AND ?",
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      final transactions =
          maps.map((map) => app_models.Transaction.fromMap(map)).toList();

      final StringBuffer csvContent = StringBuffer();
      csvContent.writeln('Date,Type,Category,Description,Amount');

      for (final transaction in transactions) {
        final category = (await getCategoryById(transaction.categoryId))!;
        csvContent.writeln(
          '${DateFormat('yyyy-MM-dd').format(transaction.date)},'
          '${transaction.type},'
          '${category.name},'
          '${transaction.description ?? ""},'
          '${transaction.amount}',
        );
      }

      return csvContent.toString();
    } catch (e) {
      print('Export error in exportToCSV: $e');
      throw Exception('Failed to generate CSV: $e');
    }
  }

  Future<void> forceReload() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await database;
  }
}
