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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    // Table for sync metadata if needed later
    await db.execute('''
      CREATE TABLE sync_info(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add userId column if it doesn't exist
      await db.execute('ALTER TABLE shopping_lists ADD COLUMN userId TEXT');
    }
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
  }
}
