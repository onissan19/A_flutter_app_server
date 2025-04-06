import 'package:flutter_app_server/database/database_helper.dart';
import 'package:flutter_app_server/managers/abstract_manager.dart';
import 'package:flutter_app_server/managers/http_logging_manager.dart';
import 'package:flutter_app_server/managers/http_server_manager.dart';
import 'package:flutter_app_server/managers/logger_manager.dart';
import 'package:flutter_app_server/managers/socket_server_manager.dart';
import 'package:flutter_app_server/managers/things_manager.dart';
import 'package:flutter_app_server/managers/app_mobile_manager.dart';

/// The global manager handles:
/// - the global state of the application
/// - the initialization of all other managers
class GlobalManager extends AbstractManager {
  /// Singleton instance of the GlobalManager
  static GlobalManager? _instance;

  /// Instance of the LoggerManager
  final LoggerManager loggerManager;

  /// Instance of the HttpLoggingManager
  final HttpLoggingManager httpLoggingManager;

  /// Instance of the HttpServerManager
  final HttpServerManager httpServerManager;

  /// Instance of the DatabaseHelper (Singleton)
  final DatabaseHelper databaseHelper;

  /// Instance of the ThingsManager (Singleton)
  final ThingsManager thingsManager;

  /// Instance of the AppMobileManager (Singleton)
  final AppMobileManager appMobileManager;

  /// Instance of the SocketServerManager (Singleton)
  final SocketServerManager socketServerManager;

  /// Singleton getter
  /// Creates a new instance if one does not already exist
  static GlobalManager get instance {
    _instance ??= GlobalManager();
    return _instance!;
  }

  /// Default constructor
  GlobalManager()
      : loggerManager = LoggerManager(),
        httpLoggingManager = HttpLoggingManager(),
        httpServerManager = HttpServerManager(),
        databaseHelper = DatabaseHelper(), // Singleton instance of the database
        thingsManager = ThingsManager(), // Singleton instance of ThingsManager
        appMobileManager = AppMobileManager(), // Singleton instance of AppMobileManager
        socketServerManager = SocketServerManager();

  /// Initializes the global manager
  /// Also initializes all dependent managers
  @override
  Future<void> initialize() async {
    // 🔹 Initialize the local database
    await databaseHelper.init();

    // Initialize the logger first so that other managers can log during setup
    await loggerManager.initialize();

    // Then initialize the HTTP logging manager so it can be used by the HTTP server manager
    await httpLoggingManager.initialize();

    // Initialize the HTTP server and other components
    await httpServerManager.initialize();

    // Initialize the socket server
    await socketServerManager.initialize();
  }

  /// Disposes the global manager and all dependent managers
  @override
  Future<void> dispose() async => Future.wait([
        loggerManager.dispose(),
        httpLoggingManager.dispose(),
        httpServerManager.dispose(),
        socketServerManager.dispose(),
      ]);
}
