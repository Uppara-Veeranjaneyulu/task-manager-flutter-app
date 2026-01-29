import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'tasks.db');

    return openDatabase(
      path,
      version: 2, // ⬅️ INCREMENT VERSION
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            dueDateTime TEXT,
            isCompleted INTEGER,
            isStarred INTEGER,
            listName TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Safe upgrade for future
        await db.execute('DROP TABLE IF EXISTS tasks');
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            dueDateTime TEXT,
            isCompleted INTEGER,
            isStarred INTEGER,
            listName TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
      },
    );
  }
}
