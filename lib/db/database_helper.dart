import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart' as app_models;
import '../models/profile.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Create profiles table
      await db.execute('''
        CREATE TABLE profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          is_selected INTEGER NOT NULL DEFAULT 0,
          icon_name TEXT
        )
      ''');

      // Insert default profile
      await db.insert('profiles', {
        'name': 'Profile 1',
        'is_selected': 1,
        'icon_name': 'person',
      });

      // Add profile_id column to transactions
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN profile_id INTEGER',
      );

      // Add profile_id column to monthly_budgets
      await db.execute(
        'ALTER TABLE monthly_budgets ADD COLUMN profile_id INTEGER',
      );

      // Set all existing transactions and budgets to default profile (id=1)
      await db.execute('UPDATE transactions SET profile_id = 1');
      await db.execute('UPDATE monthly_budgets SET profile_id = 1');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Create profiles table
    await db.execute('''
      CREATE TABLE profiles (
        id $idType,
        name $textType,
        is_selected $integerType DEFAULT 0,
        icon_name TEXT
      )
    ''');

    // Insert default profile
    await db.insert('profiles', {'name': 'Profile 1', 'is_selected': 1});

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        type $textType
      )
    ''');

    // Create transactions table with profile_id
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        amount $realType,
        type $textType,
        category_id $integerType,
        description TEXT,
        date $textType,
        profile_id $integerType,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (profile_id) REFERENCES profiles (id)
      )
    ''');

    // Create monthly_budgets table with profile_id
    await db.execute('''
      CREATE TABLE monthly_budgets (
        id $idType,
        month $textType,
        amount $realType,
        profile_id $integerType,
        FOREIGN KEY (profile_id) REFERENCES profiles (id)
      )
    ''');

    // Add default categories
    final batch = db.batch();
    batch.insert('categories', {'name': 'Groceries', 'type': 'expense'});
    batch.insert('categories', {'name': 'Transport', 'type': 'expense'});
    batch.insert('categories', {'name': 'Entertainment', 'type': 'expense'});
    batch.insert('categories', {'name': 'Salary', 'type': 'income'});
    batch.insert('categories', {'name': 'Freelance', 'type': 'income'});
    await batch.commit();
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'money_tracker.db');

    // Close the database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the database file
    if (await databaseExists(path)) {
      await deleteDatabase(path);
    }
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'money_tracker.db');

    // Close the database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the database file
    if (await databaseExists(path)) {
      await databaseFactory.deleteDatabase(path);
    }

    // Recreate database by accessing it
    await database;
  }

  // Transaction operations
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

  // Category operations
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

  Future<String> exportToCSV(DateTime startDate, DateTime endDate) async {
    try {
      late final Directory baseDir;
      late final String filePath;

      if (Platform.isAndroid) {
        // Use the public Documents directory on Android
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.documents,
        );
        if (dirs == null || dirs.isEmpty) {
          throw Exception('Could not access external storage');
        }
        baseDir = Directory('${dirs.first.path}/MaoneyTracker');
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
        final fileName =
            'transactions_${DateFormat('yyyy_MM_dd').format(startDate)}_to_${DateFormat('yyyy_MM_dd').format(endDate)}.csv';
        filePath = '${baseDir.path}/$fileName';
      } else if (Platform.isMacOS) {
        // For macOS, use ~/Documents/MaoneyTracker
        final home = Platform.environment['HOME'] ?? '';
        baseDir = Directory('$home/Documents/MaoneyTracker');
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
        final fileName =
            'transactions_${DateFormat('yyyy_MM_dd').format(startDate)}_to_${DateFormat('yyyy_MM_dd').format(endDate)}.csv';
        filePath = '${baseDir.path}/$fileName';
      } else {
        // For iOS/other, just use the default app documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        final fileName =
            'transactions_${DateFormat('yyyy_MM_dd').format(startDate)}_to_${DateFormat('yyyy_MM_dd').format(endDate)}.csv';
        filePath = '${appDocDir.path}/$fileName';
      }

      final file = File(filePath);

      final db = await database;
      final transactions = await db.rawQuery(
        '''
        SELECT t.*, c.name as category_name 
        FROM transactions t 
        LEFT JOIN categories c ON t.category_id = c.id 
        WHERE t.date BETWEEN ? AND ?
        ORDER BY t.date DESC
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      final csvData = StringBuffer();
      // Columns: Date, Type, Category, Description, Amount
      csvData.writeln('Date,Type,Category,Description,Amount');

      for (var t in transactions) {
        final date = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(t['date'] as String));
        final type = t['type'] as String;
        final category = t['category_name'] as String;
        final description = t['description'] ?? '';
        final amount = (t['amount'] as num).toStringAsFixed(2);

        // Output data in the same order as headers
        csvData.writeln('$date,"$type","$category","$description",₹$amount');
      }

      await file.writeAsString(csvData.toString());
      return filePath;
    } catch (e) {
      throw Exception('Failed to export file: $e');
    }
  }
}
