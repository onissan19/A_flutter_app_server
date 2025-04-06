/// Importing core Dart libraries
import 'dart:async'; // For asynchronous programming and Stream support
import 'dart:io'; // For handling HTTP and WebSocket servers
import 'dart:convert'; // For encoding and decoding JSON data

/// Importing project-specific modules and utilities
import 'package:flutter_app_server/data/server_constants.dart' as server_constants; // Server configuration constants
import 'package:flutter_app_server/managers/abstract_manager.dart'; // Abstract manager class
import 'package:flutter_app_server/managers/global_manager.dart'; // Global manager to access shared resources
import 'package:flutter_app_server/models/http_log.dart'; // Model for logging HTTP/WebSocket messages
import 'package:flutter_app_server/models/telemetry_data.dart'; // Model for telemetry data
import 'package:logger/logger.dart'; // Logging utility

/// Manages WebSocket communication for mobile apps and IoT devices
class SocketServerManager extends AbstractManager {
  /// A route to test the WebSocket server
  static const String helloRoute = "hello";

  /// Logger instance for logging server events
  final Logger _logger = Logger();

  /// Server instance for handling mobile app connections
  late final HttpServer _mobileAppServer;

  /// Server instance for handling IoT device connections
  late final HttpServer _thingsServer;

  /// List of connected WebSocket clients, stored by their IDs
  final Map<String, WebSocket> _connectedClients = {};

  /// StreamController to broadcast incoming telemetry data
  final StreamController<TelemetryData> _telemetryController = StreamController.broadcast();

  /// Public stream that widgets or services can subscribe to for real-time telemetry updates
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  /// Storage for all telemetry data received from clients
  final List<TelemetryData> telemetryData = [];

  /// Initializes both WebSocket servers: one for mobile apps and one for IoT things
  Future<void> initialize() async {
    _mobileAppServer = await _initServer(
      serverPort: server_constants.socketMobileAppServerPort,
      serverName: "Mobile App",
      isThingServer: false,
    );

    _thingsServer = await _initServer(
      serverPort: server_constants.socketThingsServerPort,
      serverName: "Things App",
      isThingServer: true,
    );
  }

  /// Internal method to initialize a WebSocket server
  ///
  /// [serverPort] - The port number to bind the server to
  /// [serverName] - Human-readable name of the server
  /// [isThingServer] - True if the server is for IoT devices, false for mobile apps
  Future<HttpServer> _initServer({
    required int serverPort,
    required String serverName,
    required bool isThingServer,
  }) async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
    _logger.i('Server: $serverName started on port $serverPort');

    // Listen for WebSocket upgrade requests on /ws endpoint
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/ws') {
        final WebSocket socket = await WebSocketTransformer.upgrade(request);
        _handleWebSocket(socket, isThingServer);
      }
    });

    return server;
  }

  /// Handles incoming WebSocket connections and manages authentication
  Future<void> _handleWebSocket(WebSocket socket, bool isThingServer) async {
    String? clientId;
    String? clientKey;
    bool isAuthenticated = false;

    socket.listen(
      (data) async {
        try {
          final message = jsonDecode(data as String);
          _logger.i('Message received: $message');

          if (!isAuthenticated) {
            // Ensure client is not already connected
            bool alreadyConnected = await _isClientAlreadyConnected(
              message['id'] as String,
              isThingServer,
            );

            if (alreadyConnected) {
              socket.add(jsonEncode({'error': 'Client already connected'}));
              _logger.w("Client already connected: ${message['id']}");
              socket.close();
              return;
            }

            // Try to authenticate the client
            final auth = await _authenticateClient(
              message as Map<String, dynamic>,
              isThingServer,
            );

            if (auth) {
              isAuthenticated = true;
              clientId = message['id'] as String?;
              clientKey = message['key'] as String?;

              _connectedClients[clientId!] = socket;
              socket.add(jsonEncode({'message': 'Authentication successful'}));
              _logger.i("Authentication successful for: $clientId");
            } else {
              socket.add(jsonEncode({'error': 'Authentication failed'}));
              _logger.w("Authentication failed");

              final connectionLog = HttpLog.now(
                requestId: '${DateTime.now().millisecondsSinceEpoch}',
                route: '/ws',
                method: 'Authentication',
                logLevel: Level.warning,
                message: 'Authentication failed for ${message['id']}',
              );
              GlobalManager.instance.httpLoggingManager.addLog(connectionLog);
              socket.close();
            }
          } else {
            // Handle message from authenticated clients
            _logger.i('Client message: $message');
            socket.add(jsonEncode({'response': 'Message received: $message'}));

            final connectionLog = HttpLog.now(
              requestId: '${DateTime.now().millisecondsSinceEpoch}',
              route: '/ws',
              method: 'Message',
              logLevel: Level.info,
              message: '$message',
            );
            GlobalManager.instance.httpLoggingManager.addLog(connectionLog);

            if (message['type'] == 'telemetry') {
              try {
                final dataMap = message['data'];
                final data = TelemetryData(
                  id: DateTime.now().millisecondsSinceEpoch,
                  thingId: dataMap['thingId'] as String,
                  type: dataMap['type'] as String,
                  value: dataMap['value'] as String,
                  timestamp: DateTime.now(),
                );
                addTelemetryData(data);
                socket.add(jsonEncode({'status': 'telemetry_saved'}));
                _logger.i('Telemetry data added: $data');
              } catch (e) {
                socket.add(jsonEncode({'error': 'Invalid telemetry data'}));
                _logger.e('Error adding telemetry: $e');
              }
            } else {
              socket.add(jsonEncode({'response': 'Message received: $message'}));
            }
          }
        } catch (e) {
          // Handle malformed message or unexpected error
          final connectionLog = HttpLog.now(
            requestId: '${DateTime.now().millisecondsSinceEpoch}',
            route: '/ws',
            method: 'Message',
            logLevel: Level.error,
            message: 'WebSocket processing error: $e',
          );
          GlobalManager.instance.httpLoggingManager.addLog(connectionLog);
          _logger.e('WebSocket error: $e');
          socket.add(jsonEncode({'error': 'Invalid message format'}));
          socket.close();
        }
      },
      onDone: () {
        _logger.i('Client disconnected');
        _handleDisconnection(clientId, clientKey, isThingServer);
      },
      onError: (error) {
        _logger.e('WebSocket error: $error');
        // Optionally call disconnection handler here
      },
    );
  }

  /// Checks if the client is already connected to the server
  Future<bool> _isClientAlreadyConnected(String id, bool isThingServer) async {
    if (isThingServer) {
      return await GlobalManager.instance.thingsManager.isConnected(id);
    } else {
      return await GlobalManager.instance.appMobileManager.isConnected(id);
    }
  }

  /// Authenticates a client based on its ID and secret key
  Future<bool> _authenticateClient(
    Map<String, dynamic> message,
    bool isThingServer,
  ) async {
    if (message.containsKey('id') && message.containsKey('key')) {
      final id = message['id'] as String;
      final key = message['key'] as String;

      if (isThingServer) {
        final thing = await GlobalManager.instance.thingsManager.authenticateThing(id, key);
        if (thing) {
          final connectionLog = HttpLog.now(
            requestId: '${DateTime.now().millisecondsSinceEpoch}',
            route: '/ws',
            method: 'Authentication',
            logLevel: Level.info,
            message: 'Thing $id authenticated',
          );
          GlobalManager.instance.httpLoggingManager.addLog(connectionLog);
          _logger.i('Thing $id authenticated');
          return true;
        }
      } else {
        final app = await GlobalManager.instance.appMobileManager.authenticateApp(id, key);
        if (app) {
          final connectionLog = HttpLog.now(
            requestId: '${DateTime.now().millisecondsSinceEpoch}',
            route: '/ws',
            method: 'Authentication',
            logLevel: Level.info,
            message: 'AppMobile $id authenticated',
          );
          GlobalManager.instance.httpLoggingManager.addLog(connectionLog);
          _logger.i('AppMobile $id authenticated');
          return true;
        }
      }
    }
    return false;
  }

  /// Handles cleanup when a client disconnects
  void _handleDisconnection(
    String? clientId,
    String? clientKey,
    bool isThingServer,
  ) {
    if (clientId == null || clientKey == null) return;

    if (isThingServer) {
      GlobalManager.instance.thingsManager.disconnectThing(clientId);
      _logger.i('Thing $clientId disconnected');
    } else {
      GlobalManager.instance.appMobileManager.disconnectApp(clientId);
      _logger.i('AppMobile $clientId disconnected');
    }

    // Remove from active connection list
    _connectedClients.remove(clientId);

    final connectionLog = HttpLog.now(
      requestId: '${DateTime.now().millisecondsSinceEpoch}',
      route: '/ws',
      method: 'Disconnection',
      logLevel: Level.info,
      message: '$clientId disconnected',
    );
    GlobalManager.instance.httpLoggingManager.addLog(connectionLog);
  }

  /// Disconnects a client by their ID
  void disconnectClient(String clientId) {
    final socket = _connectedClients[clientId];
    if (socket != null) {
      socket.close();
      _connectedClients.remove(clientId);
      _logger.i('Client $clientId forcibly disconnected');
    } else {
      _logger.w('Client $clientId not found for disconnection');
    }
  }

  /// Stops both WebSocket servers gracefully
  Future<void> dispose() async {
    await _mobileAppServer.close(force: true);
    await _thingsServer.close(force: true);
    _logger.i('WebSocket servers stopped');
  }

  /// Adds a telemetry data point to the internal list and broadcasts it
  void addTelemetryData(TelemetryData data) {
    telemetryData.add(data);
    _telemetryController.add(data); // Emit data to all subscribers
  }
}
