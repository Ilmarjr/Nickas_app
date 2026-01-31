import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'nickas_app.db');
    return await openDatabase(
      path,
      version: 5, // Bumped to 5
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ... Copy existing creates if this was a fresh install ...
    // But since we rely on onUpgrade for existing users, we should ideally consolidate
    // or just run _onUpgrade logic here too.
    // For specific structure simplicity, I'll define full structure here for new users

    await db.execute('''
      CREATE TABLE shopping_lists(
        id TEXT PRIMARY KEY,
        userId TEXT,
        name TEXT,
        date TEXT,
        isDeleted INTEGER DEFAULT 0,
        lastSynced TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id TEXT PRIMARY KEY,
        listId TEXT,
        name TEXT,
        brand TEXT,
        quantity REAL,
        price REAL,
        isChecked INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        lastSynced TEXT,
        FOREIGN KEY(listId) REFERENCES shopping_lists(id) ON DELETE CASCADE
      )
    ''');

    await _createFinanceTables(db); // Create new tables

    await db.execute('''
      CREATE TABLE sync_info(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _createFinanceTables(Database db) async {
    await db.execute('''
        CREATE TABLE categories(
          id TEXT PRIMARY KEY,
          name TEXT,
          color TEXT,
          icon TEXT,
          userId TEXT,
          isDeleted INTEGER DEFAULT 0,
          lastSynced TEXT
        )
      ''');

    await db.execute('''
        CREATE TABLE transactions(
          id TEXT PRIMARY KEY,
          description TEXT,
          amount REAL,
          date TEXT,
          type TEXT,
          categoryId TEXT,
          userId TEXT,
          isRecurring INTEGER DEFAULT 0,
          recurringGroupId TEXT,
          isDeleted INTEGER DEFAULT 0,
          lastSynced TEXT,
          FOREIGN KEY(categoryId) REFERENCES categories(id)
        )
      ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE shopping_lists ADD COLUMN userId TEXT');
    }
    if (oldVersion < 3) {
      await _createFinanceTables(db);
    }
    if (oldVersion < 4) {
      // Check if transactions table exists before adding column,
      // though older versions should have it if they are upgrading from 3.
      // If upgrading from < 3, _createFinanceTables handles it.
      // However, _createFinanceTables above now includes isRecurring.
      // If user was on v3, they have the table but NO column.

      // Let's protect this. If user was < 3, _createFinanceTables runs, which has the column.
      // If user was = 3, _createFinanceTables does NOT run. We need to add column.
      // So we check if table exists or just catch error?
      // Better: In _onUpgrade, sequential execution matters.

      // If oldVersion was 2, it runs <3 block -> calls _createFinanceTables.
      // With my change above, _createFinanceTables creates with isRecurring.
      // So no need to alter table if coming from < 3.

      // But if oldVersion was 3, we need to alter table.
      if (oldVersion >= 3) {
        try {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN isRecurring INTEGER DEFAULT 0',
          );
        } catch (_) {
          // Ignore if exists
        }
      }
    }
    if (oldVersion < 5) {
      // Add recurringGroupId
      if (oldVersion >= 3) {
        // Ensure table exists
        try {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN recurringGroupId TEXT',
          );
        } catch (_) {}
      }
    }
  }

  // --- CRUD Helpers for Finance ---

  Future<int> insertCategory(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(
      'categories',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    Database db = await database;
    return await db.query(
      'categories',
      where: 'isDeleted = 0 AND (userId = ? OR userId IS NULL)',
      whereArgs: [userId],
    );
  }

  Future<int> updateCategory(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'categories',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(
      'transactions',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    Database db = await database;
    return await db.query(
      'transactions',
      where: 'isDeleted = 0 AND userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> deleteTransaction(String id) async {
    Database db = await database;
    await db.update(
      'transactions',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTransaction(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'transactions',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  // Helper methods
  Future<int> insertList(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(
      'shopping_lists',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertItem(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(
      'items',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getLists(String userId) async {
    Database db = await database;
    // Filter by userId and include totalValue
    // We use a raw query to perform the join and aggregation
    return await db.rawQuery(
      '''
      SELECT 
        l.*, 
        COALESCE(SUM(i.quantity * i.price), 0) as totalValue 
      FROM shopping_lists l 
      LEFT JOIN items i ON l.id = i.listId AND i.isDeleted = 0 
      WHERE l.isDeleted = 0 AND (l.userId = ? OR l.userId IS NULL)
      GROUP BY l.id 
      ORDER BY l.date DESC
    ''',
      [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getItems(String listId) async {
    Database db = await database;
    return await db.query(
      'items',
      where: 'listId = ? AND isDeleted = 0',
      whereArgs: [listId],
    );
  }

  Future<int> updateItem(Map<String, dynamic> row) async {
    Database db = await database;
    String id = row['id'];
    return await db.update('items', row, where: 'id = ?', whereArgs: [id]);
  }

  // Soft Delete
  Future<int> deleteList(String id) async {
    Database db = await database;
    return await db.update(
      'shopping_lists',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteItem(String id) async {
    Database db = await database;
    return await db.update(
      'items',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearListsForUser(String userId) async {
    Database db = await database;
    await db.delete('shopping_lists', where: 'userId = ?', whereArgs: [userId]);
    // Also clear finance data for safety on logout (optional, but good practice for multi-user device)
    await db.delete('transactions', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('categories', where: 'userId = ?', whereArgs: [userId]);
  }
}
