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

    // Initialize both mobile app server and things server
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

    // Assign the servers to respective variables
    _mobileAppServer = result[0];
    _thingsServer = result[1];
  }

  /// Initialize the mobile app router with routes
  Future<void> _initMobileAppRouter(Router app) async {
    // Route to check if the server is working
    app.get(formatVersion1Route(_helloRoute), _getHello);

    // Route for registering a mobile app
    app.post(formatVersion1Route("register"), _registerAppMobile);

    // Route for authenticating a mobile app
    app.post(formatVersion1Route("authenticate"), _authenticateAppMobile);
  }

  /// Initialize the things app router with routes
  Future<void> _initThingsAppRouter(Router app) async {
    // Route to check if the server is working
    app.get(formatVersion1Route(_helloRoute), _getHello);

    // Route for registering a Thing (IoT device)
    app.post(formatVersion1Route("register"), _registerThing);

    // Route for authenticating a Thing
    app.post(formatVersion1Route("authenticate"), _authenticateThing);
  }

  /// Initialize the server with provided configurations
  Future<HttpServer> _initServer({
    required int serverPort,
    required String serverName,
    required Future<void> Function(Router app) initRoute,
  }) async {
    final appRouter = Router();

    // Initialize the routes for the server
    await initRoute(appRouter);

    // Start the server and log the server start
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

  /// Handle the registration of a mobile app
  Future<Response> _registerAppMobile(Request request) async {
    final body = await request.readAsString();
    final jsonData = jsonDecode(body) as Map<String, dynamic>;

    // Check for required fields: id and name
    if (!(jsonData.containsKey("id") && jsonData.containsKey("name"))) {
      return Response.badRequest(body: "Missing required fields: id, name");
    }

    // Create a new AppMobile instance and register it
    final app = AppMobile(
      id: jsonData["id"] as String,
      name: jsonData["name"] as String,
      appKey: GlobalManager.instance.appMobileManager.generateAppKey(),
      isAuth: false,
      timestamp: DateTime.now(),
    );

    final success = await GlobalManager.instance.appMobileManager.registerApp(app);

    // Respond based on the success or failure of registration
    if (success) {
      return Response.ok(jsonEncode({"message": "App registered successfully", "appKey": app.appKey}));
    } else {
      return Response.badRequest(body: jsonEncode({"error": "App already registered", "appKey": app.appKey}));
    }
  }

  /// Handle the authentication of a mobile app
  Future<Response> _authenticateAppMobile(Request request) async {
    final body = await request.readAsString();
    final jsonData = jsonDecode(body) as Map<String, dynamic>;

    // Check for required fields: id and appKey
    if (!jsonData.containsKey("id") || !jsonData.containsKey("appKey")) {
      return Response.badRequest(body: "Missing required fields: id, appKey");
    }

    // Authenticate the mobile app using the provided id and appKey
    final success = await GlobalManager.instance.appMobileManager.authenticateApp(jsonData["id"] as String, jsonData["appKey"] as String);

    // Respond based on the success or failure of authentication
    if (success) {
      return Response.ok(jsonEncode({"message": "Authentication successful"}));
    } else {
      return Response.unauthorized(jsonEncode({"error": "Invalid credentials"}));
    }
  }

  /// Handle the registration of a Thing (IoT device)
  Future<Response> _registerThing(Request request) async {
    final body = await request.readAsString();
    final jsonData = jsonDecode(body) as Map<String, dynamic>;

    // Check for required fields: id and type
    if (!jsonData.containsKey("id") || !jsonData.containsKey("type")) {
      return Response.badRequest(body: "Missing required fields: id, type");
    }

    // Create a new Thing instance and register it
    final thing = Thing(
      id: jsonData["id"] as String,
      type: jsonData["type"] as String,
      apiKey: GlobalManager.instance.thingsManager.generateApiKey(),
      isRegistered: true,
      timestamp: DateTime.now(),
    );

    final success = await GlobalManager.instance.thingsManager.registerThing(thing);

    // Respond based on the success or failure of registration
    if (success) {
      return Response.ok(jsonEncode({"message": "Thing registered successfully", "appKey": thing.apiKey}));
    } else {
      return Response.badRequest(body: jsonEncode({"error": "Thing already registered"}));
    }
  }

  /// Handle the authentication of a Thing (IoT device)
  Future<Response> _authenticateThing(Request request) async {
    final body = await request.readAsString();
    final jsonData = jsonDecode(body) as Map<String, dynamic>;

    // Check for required fields: id or apiKey
    if (!jsonData.containsKey("id") && !jsonData.containsKey("apiKey")) {
      return Response.badRequest(body: "Missing required field: id or apiKey");
    }

    // Authenticate the Thing using the provided id and apiKey
    final response = await GlobalManager.instance.thingsManager.authenticateThing(jsonData["id"] as String, jsonData["apiKey"] as String);

    // Respond based on the success or failure of authentication
    if (response) {
      return Response.ok(jsonEncode({"message": "Thing authenticated"}));
    } else {
      return Response.unauthorized(jsonEncode({"error": "Thing not found"}));
    }
  }

  /// Route to handle the hello request
  Future<Response> _getHello(Request request) =>
      _logRequest(request, (requestId) async => Response.ok('Hello, World!'));

  /// Useful method to wrap the request handling with logging
  Future<Response> _logRequest(
    Request request,
    Future<Response> Function(String requestId) handler,
  ) async {
    final requestId = shortHash(const Uuid().v1());

    // Log the incoming request
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

    // Log the response status code
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
    // Log the server closure
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
    // Close both the mobile app and things servers
    await Future.wait([_closeServer(_mobileAppServer), _closeServer(_thingsServer)]);
  }
}
