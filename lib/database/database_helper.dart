import 'package:flutter_app_server/models/app_mobile.dart';
import 'package:flutter_app_server/models/telemetry_data.dart';
import 'package:flutter_app_server/models/thing.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  // Singleton - Unique instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Unique instance accessible
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Initialize the database if it's not already initialized
  Future<void> init() async {
    if (_database == null) {
      sqfliteFfiInit(); // Initialize sqflite FFI
      databaseFactory = databaseFactoryFfi;
      _database = await _initDatabase();
    }
  }

  /// One-time creation of the database
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Create the tables in the database
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE things (
        id TEXT PRIMARY KEY,
        type TEXT,
        apiKey TEXT,
        isRegistered INTEGER,
        timestamp INTEGER
      )
    ''');

    await db.execute(''' 
      CREATE TABLE telemetry_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        thingId TEXT,
        type TEXT,
        value TEXT,
        timestamp INTEGER,
        FOREIGN KEY (thingId) REFERENCES things(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(''' 
      CREATE TABLE app_mobile (
        id TEXT PRIMARY KEY,
        name TEXT,
        app_key TEXT,
        isAuth INTEGER,
        timestamp INTEGER
      )
    ''');
  }

  /// Secure access to the database
  Future<Database> get database async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  /// 🔹 Add a Thing into the database
  Future<int> insertThing(Thing thing) async {
    final db = await database;
    return await db.insert(
      'things',
      thing.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔹 Retrieve a Thing by its ID
  Future<Thing?> getThingById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'things',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Thing.fromMap(maps.first);
    }
    return null;
  }

  /// 🔹 Retrieve all Things in the database
  Future<List<Thing>> getAllThings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('things');

    return maps.map((map) => Thing.fromMap(map)).toList();
  }

  /// 🔹 Delete a Thing by its ID
  Future<int> deleteThing(String id) async {
    final db = await database;
    return await db.delete('things', where: 'id = ?', whereArgs: [id]);
  }

  /// 🔹 CRUD - Insert TelemetryData into the database
  Future<int> insertTelemetryData(TelemetryData data) async {
    final db = await database;
    return await db.insert(
      'telemetry_data',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔹 Retrieve telemetry data associated with a Thing by its ID
  Future<List<TelemetryData>> getTelemetryByThingId(String thingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'telemetry_data',
      where: 'thingId = ?',
      whereArgs: [thingId],
    );
    return maps.map((map) => TelemetryData.fromMap(map)).toList();
  }

  /// 🔹 Delete telemetry data by Thing ID
  Future<int> deleteTelemetryByThingId(String thingId) async {
    final db = await database;
    return await db.delete(
      'telemetry_data',
      where: 'thingId = ?',
      whereArgs: [thingId],
    );
  }

  /// 🔹 CRUD - Insert AppMobile into the database
  Future<int> insertAppMobile(AppMobile app) async {
    final db = await database;
    return await db.insert(
      'app_mobile',
      app.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🔹 Retrieve AppMobile by its ID
  Future<AppMobile?> getAppById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_mobile',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AppMobile.fromMap(maps.first);
    }
    return null;
  }

  /// 🔹 Retrieve all AppMobile records
  Future<List<AppMobile>> getAllApps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('app_mobile');
    return maps.map((map) => AppMobile.fromMap(map)).toList();
  }

  /// 🔹 Delete AppMobile by its ID
  Future<int> deleteAppById(String id) async {
    final db = await database;
    return await db.delete('app_mobile', where: 'id = ?', whereArgs: [id]);
  }

  /// 🔹 Close the database properly
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null; // 🔹 Set to null after closing
    }
  }

  /// 🔹 Delete a Thing and all its associated telemetry data
  Future<bool> deleteThingWithTelemetry(String thingId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete associated telemetry data
      await txn.delete('telemetry_data', where: 'thingId = ?', whereArgs: [thingId]);

      // Delete the Thing itself
      await txn.delete('things', where: 'id = ?', whereArgs: [thingId]);
    });
    return true;
  }
}
