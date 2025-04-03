// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: MIT

import 'package:flutter_app_server/database/database_helper.dart';
import 'package:flutter_app_server/managers/abstract_manager.dart';
import 'package:flutter_app_server/managers/http_logging_manager.dart';
import 'package:flutter_app_server/managers/http_server_manager.dart';
import 'package:flutter_app_server/managers/logger_manager.dart';
import 'package:flutter_app_server/managers/things_manager.dart';

/// The global manager manages:
/// - the global state of the application
/// - the initialization of the other managers
class GlobalManager extends AbstractManager {
  /// Instance of the global manager
  static GlobalManager? _instance;

  /// Instance of the logger manager
  final LoggerManager loggerManager;

  /// Instance of the http logging manager
  final HttpLoggingManager httpLoggingManager;

  /// Instance of the http server manager
  final HttpServerManager httpServerManager;

  /// Instance of the database helper (Singleton)
  final DatabaseHelper databaseHelper;

  /// Instance getter
  /// Create a new instance if it does not exist
  static GlobalManager get instance {
    _instance ??= GlobalManager();
    return _instance!;
  }

  /// Default constructor
  GlobalManager()
      : loggerManager = LoggerManager(),
        httpLoggingManager = HttpLoggingManager(),
        httpServerManager = HttpServerManager(),
        databaseHelper = DatabaseHelper(); // 🔹 Singleton de la DB

  /// Initialize the global manager
  /// Also create and initialize the other managers
  @override
  Future<void> initialize() async {
    // 🔹 Initialisation de la base de données
    await databaseHelper.init();

    // We initialize the logger manager first, to be able to log the initialization of the other
    // managers
    await loggerManager.initialize();

    // Then, we initialize the http logging manager to be able to use it in the http server manager
    await httpLoggingManager.initialize();

    await httpServerManager.initialize();

    final ThingsManager thingsManager = ThingsManager();
    await thingsManager.populateDatabase(10);

    await thingsManager.printAllThings();
  }

  /// Dispose the global manager and the linked managers
  @override
  Future<void> dispose() async => Future.wait([
        loggerManager.dispose(),
        httpLoggingManager.dispose(),
        httpServerManager.dispose(),
      ]);
}
