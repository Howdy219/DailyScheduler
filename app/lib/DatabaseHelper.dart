import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // pattern to ensure only one instance of DatabaseHelper
  DatabaseHelper._privateConstructor();

  // initialization of the database
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fitness.db');
    return openDatabase(path, onCreate: (db, version) async {
      // Create the Fitness table
      await db.execute(''' 
        CREATE TABLE Fitness (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weekday TEXT,
          workout_name TEXT,
          weight REAL,
          sets_reps TEXT
        );
      ''');

      // Create the BodyWeight table
      await db.execute(''' 
        CREATE TABLE BodyWeight (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          body_weight REAL
        );
      ''');
    }, version: 1);
  }

  // Insert a workout into the Fitness table
  Future<int> insertWorkout(Map<String, dynamic> workout) async {
    final db = await database;
    return await db.insert('Fitness', workout);
  }


  // Insert a body weight entry into the BodyWeight table
  Future<int> insertBodyWeight(Map<String, dynamic> bodyWeight) async {
    final db = await database;
    return await db.insert('BodyWeight', bodyWeight);
  }


  // Get all workouts from the Fitness table
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await database;
    return await db.query('Fitness');
  }


  // Get all body weight records
  Future<List<Map<String, dynamic>>> getBodyWeight() async {
    final db = await database;
    return await db.query('BodyWeight');
  }


  // Get the most recent workout for each workout_name on a specific weekday
  Future<List<Map<String, dynamic>>> getMostRecentWorkoutsForDay(String weekday) async {
    final db = await database;
    var res = await db.rawQuery('''
      SELECT * FROM Fitness
      WHERE weekday = ?
      AND id IN (
        SELECT MAX(id) FROM Fitness WHERE weekday = ? GROUP BY workout_name
      )
    ''', [weekday, weekday]);

    return res.isNotEmpty ? res : [];
  }

  // Get workouts for a specific weekday
  Future<List<Map<String, dynamic>>> getWorkoutsForDay(String weekday) async {
    final db = await database;
    return await db.query(
      'Fitness',
      where: 'weekday = ?',
      whereArgs: [weekday],
    );
  }

  // Update a workout in fitness
  Future<int> updateWorkout(Map<String, dynamic> workout, int id) async {
    final db = await database;
    return await db.update(
      'Fitness',
      workout,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a workout from fitness by its ID
  Future<int> deleteWorkout(int id) async {
    final db = await database;
    return await db.delete(
      'Fitness',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all workouts for a specific weekday
  Future<int> deleteWorkoutsForDay(String weekday) async {
    final db = await database;
    return await db.delete(
      'Fitness',
      where: 'weekday = ?',
      whereArgs: [weekday],
    );
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts() async {
    final db = await database;
    return await db.query('Fitness'); // Gets all records from fitness
  }

}
