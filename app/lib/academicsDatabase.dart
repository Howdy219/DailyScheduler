import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print(path);
    
    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

Future<void> _createDB(Database db, int version) async {
           await db.execute('''
            CREATE TABLE IF NOT EXISTS events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                month INTEGER,
                day INTEGER,
                year INTEGER,
                eventName TEXT,
                eventDescription TEXT,
                importance INTEGER
            )
        ''');

        await db.execute('''
            CREATE TABLE IF NOT EXISTS assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                assignmentName TEXT,
                gradeWorth REAL,
                courseName TEXT,
                courseAverage REAL
            )
        ''');

        await db.execute('''
            CREATE TABLE IF NOT EXISTS courses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                courseName TEXT,
                courseGrade REAL,
                overallGPA REAL
            )
        ''');
    

}
Future<void> deleteDatabaseFile() async {
    String path = join(await getDatabasesPath(), 'academics.db');
    await deleteDatabase(path);
    print("Database deleted");
}



  Future<List<Map<String, dynamic>>> getEvents(int month, int day, int year) async {
    final db = await database;

    return await db.query(
      'events',
      where: 'month = ? AND day = ? AND year = ?',
      whereArgs: [month, day, year],
    );
  }

  Future<int> addTask(int month, int day, int year, String eventName, String eventDescription, int importance) async {
    final db = await database;
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print("Existing tables: $tables");

    return await db.insert('events', {
      'month': month,
      'day': day,
      'year': year,
      'eventName': eventName,
      'eventDescription': eventDescription,
      'importance': importance,
    });
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addAssignment(String assignmentName, double gradeWorth, String courseName, double courseAverage) async {
    final db = await database;
    return await db.insert('assignments', {
      'assignmentName': assignmentName,
      'gradeWorth': gradeWorth,
      'courseName': courseName,
      'courseAverage': courseAverage,
    });
  }

  

  Future<List<Map<String, dynamic>>> getAssignments(String courseName) async {
    final db = await database;
    return await db.query(
      'assignments',
      where: 'courseName = ?',
      whereArgs: [courseName],
    );
  }

  Future<int> deleteAssignment(int id) async {
    final db = await database;
    return await db.delete('assignments', where: 'id = ?', whereArgs: [id]);
  }

  
  Future<int> addCourse(String courseName) async {
    final db = await database;
    return await db.insert(
      'courses',
      {
        'courseName': courseName,
        'courseGrade': 0.0,
        'overallGPA': 0.0,
      },

    );
  }
  Future<int> updateAssignment(int id, String assignmentName, double gradeWorth, String courseName, double? courseAverage) async {
        final db = await database;
        return await db.update(
            'assignments',
            {
                'assignmentName': assignmentName,
                'gradeWorth': gradeWorth,
                'courseName': courseName,
                'courseAverage': courseAverage,
            },
            where: 'id = ?',
            whereArgs: [id],
        );
    }

}
