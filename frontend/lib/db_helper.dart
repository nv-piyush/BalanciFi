import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, priority TEXT)',
        );
      },
    );
  }

  // Insert Task
  static Future<void> insertTask(String title, String priority) async {
    final db = await database;
    await db.insert('tasks', {'title': title, 'priority': priority});
  }

  // Fetch All Tasks
  static Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'id DESC');
  }

  // Update Task
  static Future<void> updateTask(int id, String title, String priority) async {
    final db = await database;
    await db.update(
      'tasks',
      {'title': title, 'priority': priority},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete Task
  static Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
