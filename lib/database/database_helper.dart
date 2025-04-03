import 'package:flutter_app_server/models/app_mobile.dart';
import 'package:flutter_app_server/models/telemetry_data.dart';
import 'package:flutter_app_server/models/thing.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  // Singleton - Instance unique
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Instance unique accessible
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // Initialisation de la base de données
  Future<void> init() async {
    if (_database == null) {
      sqfliteFfiInit(); // 🔹 Nécessaire pour les plateformes desktop
      databaseFactory = databaseFactoryFfi;
      _database = await _initDatabase();
    }
  }

  // Création unique de la base
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Création des tables
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

  // Accès sécurisé à la base
  Future<Database> get database async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  // 🔹 Ajouter un Thing
  Future<int> insertThing(Thing thing) async {
    final db = await database;
    return await db.insert(
      'things',
      thing.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🔹 Récupérer un Thing par ID
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

  // 🔹 Récupérer tous les Things
  Future<List<Thing>> getAllThings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('things');

    return maps.map((map) => Thing.fromMap(map)).toList();
  }

  // 🔹 Supprimer un Thing
  Future<int> deleteThing(String id) async {
    final db = await database;
    return await db.delete('things', where: 'id = ?', whereArgs: [id]);
  }

  // 🔹 CRUD - TelemetryData
  Future<int> insertTelemetryData(TelemetryData data) async {
    final db = await database;
    return await db.insert(
      'telemetry_data',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TelemetryData>> getTelemetryByThingId(String thingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'telemetry_data',
      where: 'thingId = ?',
      whereArgs: [thingId],
    );
    return maps.map((map) => TelemetryData.fromMap(map)).toList();
  }

  Future<int> deleteTelemetryByThingId(String thingId) async {
    final db = await database;
    return await db.delete(
      'telemetry_data',
      where: 'thingId = ?',
      whereArgs: [thingId],
    );
  }

  // 🔹 CRUD - AppMobile
  Future<int> insertAppMobile(AppMobile app) async {
    final db = await database;
    return await db.insert(
      'app_mobile',
      app.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<List<AppMobile>> getAllApps() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('app_mobile');
    return maps.map((map) => AppMobile.fromMap(map)).toList();
  }

  Future<int> deleteAppById(String id) async {
    final db = await database;
    return await db.delete('app_mobile', where: 'id = ?', whereArgs: [id]);
  }

  // 🔹 Fermer la base de données proprement
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null; // 🔹 Remettre à null après fermeture
    }
  }


// 🔹 Supprimer un Thing et toutes ses données de télémétrie associées
Future<bool> deleteThingWithTelemetry(String thingId) async {
  final db = await database;
  await db.transaction((txn) async {
    // Supprimer les données de télémétrie associées
    await txn.delete('telemetry_data', where: 'thingId = ?', whereArgs: [thingId]);

    // Supprimer le Thing lui-même
    await txn.delete('things', where: 'id = ?', whereArgs: [thingId]);
  });
  return true;
}



}
