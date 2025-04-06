import 'dart:async';
import 'dart:math';
import 'package:flutter_app_server/database/database_helper.dart';
import 'package:flutter_app_server/models/app_mobile.dart';

class AppMobileManager {
  // List of authenticated applications
  final List<AppMobile> authenticatedApps = [];

  // StreamController to notify changes
  final StreamController<List<AppMobile>> _appsStreamController = StreamController.broadcast();

  // Getter to listen for changes
  Stream<List<AppMobile>> get appsStream => _appsStreamController.stream;

  // Private constructor to prevent direct instantiation
  static final AppMobileManager _instance = AppMobileManager._internal();

  // Factory to access the singleton instance
  factory AppMobileManager() {
    return _instance;
  }

  AppMobileManager._internal();

  // Generate a random application key
  String generateAppKey() {
    final random = Random();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }

  // Retrieve an AppMobile by ID (first in memory, then in the database)
  Future<AppMobile?> getAppById(String id) async {
    for (var app in authenticatedApps) {
      if (app.id == id) {
        return app;
      }
    }
    return await DatabaseHelper().getAppById(id);
  }

  // Register a new mobile application
  Future<bool> registerApp(AppMobile app) async {
    if (await getAppById(app.id) != null) {
      return false; // The application is already registered
    }

    app.isAuth = false;
    app.timestamp = DateTime.now();

    await DatabaseHelper().insertAppMobile(app);
    _notifyListeners(); // Notify listeners about the change

    return true;
  }

  // Check if an app is connected by ID
  Future<bool> isConnected(String id) async {
    final app = await getAppById(id);
    if (app != null) {
      if (authenticatedApps.contains(app)) {
        return true;
      }
      return false;
    }
    return false;
  }

  // Authenticate a mobile application
  Future<bool> authenticateApp(String id, String appKey) async {
    final app = await getAppById(id);
    if (app != null && app.appKey == appKey) {
      app.isAuth = true;
      if (!authenticatedApps.contains(app)) {
        authenticatedApps.add(app);
        _notifyListeners(); // Notify listeners about the change
      }
      return true;
    }
    return false;
  }

  // Disconnect a mobile application (remove it from the authenticated list)
  void disconnectApp(String id) {
    authenticatedApps.removeWhere((app) => app.id == id);
    _notifyListeners(); // Notify listeners about the change
  }

  // Unregister a mobile application (also deletes associated data)
  Future<bool> unregisterApp(String id) async {
    final app = await getAppById(id);
    if (app == null) return false;

    // Disconnect the app first
    disconnectApp(id);

    // Then delete it from the database
    await DatabaseHelper().deleteAppById(id);

    _notifyListeners(); // Notify listeners after deletion
    return true;
  }

  // Retrieve all mobile applications from the database
  Future<List<AppMobile>> getAllAppsFromDatabase() async {
    return await DatabaseHelper().getAllApps();
  }

  // Retrieve all connected mobile applications
  List<AppMobile> getConnectedApps() {
    return List.unmodifiable(authenticatedApps);
  }

  // Generate a random AppMobile
  AppMobile generateRandomApp() {
    final random = Random();
    return AppMobile(
      id: 'app_${random.nextInt(1000)}',
      name: 'App ${random.nextInt(100)}',
      appKey: generateAppKey(),
      isAuth: false,
      timestamp: DateTime.now(),
    );
  }

  // Populate the database with random mobile applications
  Future<void> populateDatabase(int count) async {
    for (int i = 0; i < count; i++) {
      final app = generateRandomApp();
      await registerApp(app);
    }
    _notifyListeners(); // Notify after mass addition
  }

  // Print all registered mobile applications
  Future<void> printAllApps() async {
    final apps = await getAllAppsFromDatabase();
    if (apps.isEmpty) {
      print('No applications registered.');
    } else {
      print('List of registered applications:');
      for (var app in apps) {
        print(app);
      }
    }
  }

  // Notify listeners in case of an update to the list
  void _notifyListeners() {
    _appsStreamController.add(List.unmodifiable(authenticatedApps));
  }

  // Close the StreamController when no longer needed
  void dispose() {
    _appsStreamController.close();
  }
}
