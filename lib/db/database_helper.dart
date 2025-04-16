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
    batch.insert('categories', {'name': 'Salary', 'type': 'income'});
    batch.insert('categories', {'name': 'Freelance', 'type': 'income'});
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

  Future<String> exportToCSV(DateTime startDate, DateTime endDate) async {
    try {
      print('Starting exportToCSV for dates: $startDate to $endDate');
      late String filePath;
      final fileName =
          'transactions_${DateFormat('yyyy_MM_dd').format(startDate)}_to_${DateFormat('yyyy_MM_dd').format(endDate)}.csv';

      if (Platform.isAndroid) {
        // Use Documents directory for consistent behavior
        final directory = Directory(
          '/storage/emulated/0/Documents/MoneyTracker',
        );

        print('Attempting to access directory: ${directory.path}');
        if (!await directory.exists()) {
          print('Directory does not exist, creating: ${directory.path}');
          await directory.create(recursive: true);
        }

        filePath = '${directory.path}/$fileName';
      } else if (Platform.isIOS || Platform.isMacOS) {
        final directory = await getApplicationDocumentsDirectory();
        final moneyTrackerDir = Directory('${directory.path}/MoneyTracker');
        if (!await moneyTrackerDir.exists()) {
          await moneyTrackerDir.create(recursive: true);
        }
        filePath = '${moneyTrackerDir.path}/$fileName';
        print('iOS/macOS: Saving file to: $filePath');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final moneyTrackerDir = Directory('${directory.path}/MoneyTracker');
        if (!await moneyTrackerDir.exists()) {
          await moneyTrackerDir.create(recursive: true);
        }
        filePath = '${moneyTrackerDir.path}/$fileName';
        print('Other platform: Saving file to: $filePath');
      }

      final file = File(filePath);

      final db = await database;
      print('Querying transactions from database...');
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
      csvData.writeln('Date,Type,Category,Description,Amount');

      for (var t in transactions) {
        final date = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(t['date'] as String));
        final type = t['type'] as String;
        final category = t['category_name'] as String;
        final description = t['description'] ?? '';
        final amount = (t['amount'] as num).toStringAsFixed(2);
        csvData.writeln('$date,"$type","$category","$description",₹$amount');
      }

      print('Writing CSV file to: $filePath');
      await file.writeAsString(csvData.toString());
      print('File successfully written to: $filePath');
      return filePath;
    } catch (e) {
      print('Export error in exportToCSV: $e');
      throw Exception('Failed to export file: $e');
    }
  }
}
