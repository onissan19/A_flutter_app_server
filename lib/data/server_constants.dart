// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: MIT

library;

/// This is the server hostname for the http server
/// Set to "0.0.0.0" to allow the server to listen on all available network interfaces
final serverHostname = "0.0.0.0";

/// This is the server port for the HTTP mobile app server
/// Used for handling requests related to the mobile application
const mobileAppServerPort = 4000;

/// This is the server port for the HTTP things server
/// Used for handling requests related to "things" (IoT devices)
const thingsServerPort = 4001;

/// This is the server port for the WebSocket mobile app server
/// Handles real-time communication with the mobile app
const socketMobileAppServerPort = 5000;

/// This is the server port for the WebSocket things server
/// Handles real-time communication with "things" (IoT devices)
const socketThingsServerPort = 5001;
