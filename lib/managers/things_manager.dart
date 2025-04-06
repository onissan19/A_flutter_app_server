import 'dart:async';
import 'dart:math';
import 'package:flutter_app_server/database/database_helper.dart';
import 'package:flutter_app_server/models/thing.dart';

/// Manages registered "Thing" objects and their interactions
class ThingsManager {
  /// List of registered objects
  final List<Thing> registeredThings = [];

  /// StreamController to notify changes in the list of registered objects
  final StreamController<List<Thing>> _thingsStreamController = StreamController.broadcast();

  /// Stream to listen for changes in the list of registered objects
  Stream<List<Thing>> get thingsStream => _thingsStreamController.stream;

  /// Singleton instance of [ThingsManager]
  static final ThingsManager _instance = ThingsManager._internal();

  /// Factory constructor to return the singleton instance
  factory ThingsManager() => _instance;

  /// Private constructor to prevent instantiation from outside the class
  ThingsManager._internal();

  /// Generates a random API key
  String generateApiKey() {
    final random = Random();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }

  /// Retrieves a "Thing" by its ID (checks the list first, then the database)
  Future<Thing?> getThingById(String id) async {
    for (var thing in registeredThings) {
      if (thing.id == id) {
        return thing;
      }
    }
    return await DatabaseHelper().getThingById(id);
  }

  /// Registers a new "Thing"
  Future<bool> registerThing(Thing thing) async {
    if (await DatabaseHelper().getThingById(thing.id) != null) {
      return false; // The object is already registered in the database
    }
    await DatabaseHelper().insertThing(thing);
    _notifyListeners(); // Notify changes
    return true;
  }

  /// Disconnects a "Thing" (removes it from the list)
  void disconnectThing(String id) {
    registeredThings.removeWhere((thing) => thing.id == id);
    _notifyListeners(); // Notify changes
  }

  /// Authenticates a "Thing" by its ID and API key
  Future<bool> authenticateThing(String id, String apiKey) async {
    final thing = await getThingById(id);
    if (thing != null && thing.apiKey == apiKey) {
      thing.isRegistered = true; // Authentication successful
      if (!registeredThings.contains(thing)) {
        registeredThings.add(thing);
        _notifyListeners(); // Notify changes
      }
      return true;
    }
    return false;
  }

  /// Retrieves all "Things" from the database
  Future<List<Thing>> getAllThingsFromDatabase() async => await DatabaseHelper().getAllThings();

  /// Generates a random "Thing"
  Thing generateRandomThing() {
    final random = Random();
    return Thing(
      id: 'thing_${random.nextInt(1000)}',
      type: ['sensor', 'device', 'gadget'][random.nextInt(3)],
      apiKey: null,
      isRegistered: false,
      timestamp: DateTime.now(),
    );
  }

  /// Fills the database with random objects
  Future<void> populateDatabase(int count) async {
    for (int i = 0; i < count; i++) {
      final thing = generateRandomThing();
      await registerThing(thing);
    }
    _notifyListeners(); // Notify after bulk addition
  }

  /// Unregisters a "Thing" (also deletes telemetry data)
  Future<bool> unregisterThing(String id) async {
    final thing = await DatabaseHelper().getThingById(id);
    if (thing == null) return false;

    // First disconnect the object
    disconnectThing(id);

    // Then delete it from the database
    await DatabaseHelper().deleteThingWithTelemetry(id);

    _notifyListeners(); // Notify after deletion
    return true;
  }

  /// Checks if a "Thing" is currently connected
  Future<bool> isConnected(String id) async {
    final thing = await getThingById(id);
    if (thing != null) {
      return registeredThings.contains(thing);
    }
    return false;
  }

  /// Retrieves all connected "Things"
  List<Thing> getConnectedThings() => List.unmodifiable(registeredThings);

  /// Prints all registered objects
  Future<void> printAllThings() async {
    final things = await getAllThingsFromDatabase();
    if (things.isEmpty) {
      print('No registered Things.');
    } else {
      print('List of registered Things:');
      for (var thing in things) {
        print(thing);
      }
    }
  }

  /// Notifies subscribers about updates to the list
  void _notifyListeners() {
    _thingsStreamController.add(List.unmodifiable(registeredThings));
  }

  /// Closes the StreamController when no longer needed
  void dispose() {
    _thingsStreamController.close();
  }
}