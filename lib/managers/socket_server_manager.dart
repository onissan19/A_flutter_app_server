import 'dart:io';
import 'dart:convert';
import 'package:flutter_app_server/data/server_constants.dart' as server_constants;
import 'package:flutter_app_server/managers/abstract_manager.dart';
import 'package:flutter_app_server/managers/global_manager.dart';
import 'package:logger/logger.dart';

class SocketServerManager extends AbstractManager {
  static const String helloRoute = "hello";
  final Logger _logger = Logger();

  /// Serveur pour les applications mobiles
  late final HttpServer _mobileAppServer;

  /// Serveur pour les objets
  late final HttpServer _thingsServer;

  /// Initialisation du serveur WebSocket
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

  /// Initialisation du serveur WebSocket
  Future<HttpServer> _initServer({
    required int serverPort,
    required String serverName,
    required bool isThingServer,
  }) async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
    _logger.i('Server: $serverName started on port $serverPort');

    server.listen((HttpRequest request) async {
      if (request.uri.path == '/ws') {
        final WebSocket socket = await WebSocketTransformer.upgrade(request);
        _handleWebSocket(socket, isThingServer);
      }
    });

    return server;
  }

  /// Gestion d'une connexion WebSocket (auth + messages)
  Future<void> _handleWebSocket(WebSocket socket, bool isThingServer) async {
    String? clientId;
    String? clientKey;
    bool isAuthenticated = false;

    socket.listen(
      (data) async {
        try {
          final message = jsonDecode(data as String);
          _logger.i('Message reçu: $message');

          if (!isAuthenticated) {
            // Vérifier si le client est déjà connecté avant d'authentifier
            bool alreadyConnected = await _isClientAlreadyConnected(
              message['id'] as String,
              isThingServer,
            );

            if (alreadyConnected) {
              socket.add(jsonEncode({'error': 'Client already connected'}));
              _logger.w("Client déjà connecté : ${message['id']}");
              socket.close();
              return;
            }

            final auth = await _authenticateClient(
              message as Map<String, dynamic>,
              isThingServer,
            );

            if (auth) {
              isAuthenticated = true;
              clientId = message['id'] as String?;
              clientKey = message['key'] as String?;
              socket.add(jsonEncode({'message': 'Authentication successful'}));
              _logger.i("Authentification réussie pour: $clientId");
            } else {
              socket.add(jsonEncode({'error': 'Authentication failed'}));
              _logger.w("Authentification échouée");
              socket.close();
            }
          } else {
            // Client déjà authentifié, traiter les messages
            _logger.i('Message client: $message');
            socket.add(jsonEncode({'response': 'Message received: $message'}));
          }
        } catch (e) {
          _logger.e('Erreur de traitement WebSocket: $e');
          socket.add(jsonEncode({'error': 'Invalid message format'}));
          socket.close();
        }
      },
      onDone: () {
        _logger.i('Client déconnecté');
        _handleDisconnection(clientId, clientKey, isThingServer);
      },
      onError: (error) {
        _logger.e('Erreur WebSocket: $error');
        _handleDisconnection(clientId, clientKey, isThingServer);
      },
    );
  }

  /// Vérifie si un client est déjà connecté
  Future<bool> _isClientAlreadyConnected(String id, bool isThingServer) async {
    if (isThingServer) {
      return await GlobalManager.instance.thingsManager.isConnected(id);
    } else {
      return await GlobalManager.instance.appMobileManager.isConnected(id);
    }
  }

  /// Authentifie un client (App ou Thing)
  Future<bool> _authenticateClient(Map<String, dynamic> message, bool isThingServer) async {
    if (message.containsKey('id') && message.containsKey('key')) {
      final id = message['id'] as String;
      final key = message['key'] as String;

      if (isThingServer) {
        final thing = await GlobalManager.instance.thingsManager.authenticateThing(id, key);
        if (thing) {
          _logger.i('Thing $id authenticated');
          return true;
        }
      } else {
        final app = await GlobalManager.instance.appMobileManager.authenticateApp(id, key);
        if (app) {
          _logger.i('AppMobile $id authenticated');
          return true;
        }
      }
    }
    return false;
  }

  /// Gestion de la déconnexion
  void _handleDisconnection(String? clientId, String? clientKey, bool isThingServer) {
    if (clientId == null || clientKey == null) return;

    if (isThingServer) {
      GlobalManager.instance.thingsManager.disconnectThing(clientId);
      _logger.i(' Thing $clientId déconnecté');
    } else {
      GlobalManager.instance.appMobileManager.disconnectApp(clientId);
      _logger.i('AppMobile $clientId déconnecté');
    }
  }

  /// Arrêt des serveurs
  Future<void> dispose() async {
    await _mobileAppServer.close(force: true);
    await _thingsServer.close(force: true);
    _logger.i('WebSocket servers stopped');
  }
}
