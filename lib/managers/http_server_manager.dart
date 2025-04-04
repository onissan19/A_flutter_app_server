// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:convert';

import 'package:flutter_app_server/data/server_constants.dart' as server_constants;
import 'package:flutter_app_server/managers/abstract_manager.dart';
import 'package:flutter_app_server/managers/global_manager.dart';
import 'package:flutter_app_server/managers/http_logging_manager.dart';
import 'package:flutter_app_server/models/app_mobile.dart';
import 'package:flutter_app_server/models/http_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_server/models/thing.dart';
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

/// This class is used to manage the http server
/// It will create a server and listen to the requests
class HttpServerManager extends AbstractManager {
  static const _api = "api";

  static const _version1 = "v1";

  static const _helloRoute = "hello";

  /// Instance of the http mobile app server
  late final HttpServer _mobileAppServer;

  /// Instance of the http things server
  late final HttpServer _thingsServer;

  /// Instance of the http logging manager
  late final HttpLoggingManager _httpLoggingManager;

  /// {@macro abstract_manager.initialize}
  @override
  Future<void> initialize() async {
    _httpLoggingManager = GlobalManager.instance.httpLoggingManager;

    final result = await Future.wait([
      _initServer(
        serverPort: server_constants.mobileAppServerPort,
        serverName: "Mobile App",
        initRoute: _initMobileAppRouter,
      ),
      _initServer(
        serverPort: server_constants.thingsServerPort,
        serverName: "Things App",
        initRoute: _initThingsAppRouter,
      ),
    ]);

    _mobileAppServer = result[0];
    _thingsServer = result[1];
  }

/// Initialize the mobile app router
Future<void> _initMobileAppRouter(Router app) async {
  app.get(formatVersion1Route(_helloRoute), _getHello);

  // Route pour enregistrer une application mobile
  app.post(formatVersion1Route("register"), _registerAppMobile);

  // Route pour authentifier une application mobile
  app.post(formatVersion1Route("authenticate"), _authenticateAppMobile);
}

/// Initialize the things app router
Future<void> _initThingsAppRouter(Router app) async {
  app.get(formatVersion1Route(_helloRoute), _getHello);

  // Route pour enregistrer un Thing
  app.post(formatVersion1Route("register"), _registerThing);

  // Route pour authentifier un Thing
  app.post(formatVersion1Route("authenticate"), _authenticateThing);
}

  /// Initialize the server
  Future<HttpServer> _initServer({
    required int serverPort,
    required String serverName,
    required Future<void> Function(Router app) initRoute,
  }) async {
    final appRouter = Router();

    await initRoute(appRouter);

    final server = await io.serve(appRouter.call, server_constants.serverHostname, serverPort);
    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: "server-start",
        route: '/',
        method: '/',
        logLevel: Level.info,
        message: 'Server: $serverName started on ${server.address.host}:${server.port}',
      ),
    );

    return server;
  }


  Future<Response> _registerAppMobile(Request request) async {
  final body = await request.readAsString();
  final jsonData = jsonDecode(body) as Map<String, dynamic>;
  

  if (!(jsonData.containsKey("id") && jsonData.containsKey("name"))) {
    return Response.badRequest(body: "Missing required fields: id, name");
  }

  final app = AppMobile(
    id: jsonData["id"] as String,
    name: jsonData["name"] as String,
    appKey: GlobalManager.instance.appMobileManager.generateAppKey(),
    isAuth: false,
    timestamp: DateTime.now(),
  );

  final success = await GlobalManager.instance.appMobileManager.registerApp(app);
  
  if (success) {
    return Response.ok(jsonEncode({"message": "App registered successfully", "appKey": app.appKey}));
  } else {
    return Response.badRequest(body: jsonEncode({"error": "App already registered","appKey": app.appKey}));
  }
}


Future<Response> _authenticateAppMobile(Request request) async {
  final body = await request.readAsString();
  final jsonData = jsonDecode(body) as Map<String, dynamic>;

  if (!jsonData.containsKey("id") || !jsonData.containsKey("appKey")) {
    return Response.badRequest(body: "Missing required fields: id, appKey");
  }

  final success = await GlobalManager.instance.appMobileManager.authenticateApp(jsonData["id"] as String, jsonData["appKey"] as String);
  
  if (success) {
    return Response.ok(jsonEncode({"message": "Authentication successful"}));
  } else {
    return Response.unauthorized(jsonEncode({"error": "Invalid credentials"}));
  }
}

Future<Response> _registerThing(Request request) async {
  final body = await request.readAsString();
  final jsonData = jsonDecode(body) as Map<String, dynamic>;

  if (!jsonData.containsKey("id") || !jsonData.containsKey("type")) {
    return Response.badRequest(body: "Missing required fields: id, type");
  }

  final thing = Thing(
    id: jsonData["id"] as String,
    type: jsonData["type"] as String,
    apiKey: GlobalManager.instance.thingsManager.generateApiKey(),
    isRegistered: true,
     timestamp: DateTime.now(),
  );

  final success = await GlobalManager.instance.thingsManager.registerThing(thing);
  
  if (success) {
    return Response.ok(jsonEncode({"message": "Thing registered successfully","appKey": thing.apiKey}));
  } else {
    return Response.badRequest(body: jsonEncode({"error": "Thing already registered"}));
  }
}

Future<Response> _authenticateThing(Request request) async {
  final body = await request.readAsString();
  final jsonData = jsonDecode(body) as Map<String, dynamic>;

  if (!jsonData.containsKey("id") && !jsonData.containsKey("apiKey")) {
    return Response.badRequest(body: "Missing required field: id or apikey");
  }

  
  final response = await GlobalManager.instance.thingsManager.authenticateThing(jsonData["id"] as String, jsonData["apiKey"] as String);

  if (response) {
    return Response.ok(jsonEncode({"message": "Thing authenticated"}));
  } else {
    return Response.unauthorized(jsonEncode({"error": "Thing not found"}));
  }
}



  /// Route to handle the hello request
  Future<Response> _getHello(Request request) =>
      _logRequest(request, (requestId) async => Response.ok('Hello, World!'));

  /// Useful method to wraps the request handling with logging
  Future<Response> _logRequest(
    Request request,
    Future<Response> Function(String requestId) handler,
  ) async {
    final requestId = shortHash(const Uuid().v1());

    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: requestId,
        route: request.requestedUri.toString(),
        method: request.method,
        logLevel: Level.info,
        message: "Received request",
      ),
    );
    final response = await handler(requestId);
    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: requestId,
        route: request.requestedUri.toString(),
        method: request.method,
        logLevel: Level.info,
        message: "Responded with status code ${response.statusCode}",
      ),
    );
    return response;
  }

  /// Close the given [server]
  Future<void> _closeServer(HttpServer server) async {
    _httpLoggingManager.addLog(
      HttpLog.now(
        requestId: "server-close",
        route: '/',
        method: '/',
        logLevel: Level.info,
        message: 'Server closed on ${server.address.host}:${server.port}',
      ),
    );
    await server.close(force: true);
  }

  /// Format the route for the server
  static String formatVersion1Route(String route) => '/$_api/$_version1/$route';

  /// {@macro abstract_manager.dispose}
  @override
  Future<void> dispose() async {
    await Future.wait([_closeServer(_mobileAppServer), _closeServer(_thingsServer)]);
  }
}
