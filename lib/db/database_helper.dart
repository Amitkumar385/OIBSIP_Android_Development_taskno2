import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todo_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            is_done INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
      },
    );
  }

  static String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static Future<bool> registerUser(String username, String password) async {
    final db = await database;
    try {
      await db.insert('users', {
        'username': username.trim(),
        'password': _hash(password),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username.trim(), _hash(password)],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  static Future<int> addTask({
    required int userId,
    required String title,
    required String description,
    required String type,
  }) async {
    final db = await database;
    return await db.insert('tasks', {
      'user_id': userId,
      'title': title.trim(),
      'description': description.trim(),
      'type': type,
      'is_done': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getTasks(int userId) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<void> toggleDone(int id, bool isDone) async {
    final db = await database;
    await db.update(
      'tasks',
      {'is_done': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateTask(int id, String title, String description) async {
    final db = await database;
    await db.update(
      'tasks',
      {'title': title.trim(), 'description': description.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
