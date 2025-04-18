import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as app_models;
import '../models/category.dart' as app_models;
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
      await db.execute('''
        CREATE TABLE profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          is_selected INTEGER NOT NULL DEFAULT 0,
          icon_name TEXT
        )
      ''');

      await db.insert('profiles', {
        'name': 'Profile 1',
        'is_selected': 1,
        'icon_name': 'person',
      });

      await db.execute(
        'ALTER TABLE transactions ADD COLUMN profile_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE monthly_budgets ADD COLUMN profile_id INTEGER',
      );
      await db.execute('UPDATE transactions SET profile_id = 1');
      await db.execute('UPDATE monthly_budgets SET profile_id = 1');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE profiles (
        id $idType,
        name $textType,
        is_selected $integerType DEFAULT 0,
        icon_name TEXT
      )
    ''');

    await db.insert('profiles', {'name': 'Profile 1', 'is_selected': 1});

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
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (profile_id) REFERENCES profiles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_budgets (
        id $idType,
        month $textType,
        amount $realType,
        profile_id $integerType,
        FOREIGN KEY (profile_id) REFERENCES profiles (id)
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

      // Create CSV content
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
}
