// Importing core Dart asynchronous utilities to work with Streams and Subscriptions
import 'dart:async';

// Importing Flutter's UI framework
import 'package:flutter/material.dart';

// Importing the TelemetryData model which contains telemetry information from Things
import 'package:flutter_app_server/models/telemetry_data.dart';

// Importing GlobalManager to access shared managers like the socket server
import 'package:flutter_app_server/managers/global_manager.dart';

/// A widget that displays real-time telemetry data for a specific Thing (device).
/// It listens to incoming telemetry data and updates the UI live.
class TelemetryLiveWidget extends StatefulWidget {
  /// The ID of the Thing for which we want to show live telemetry
  final String thingId;

  const TelemetryLiveWidget({Key? key, required this.thingId}) : super(key: key);

  @override
  State<TelemetryLiveWidget> createState() => _TelemetryLiveWidgetState();
}

/// The state class that manages subscription to telemetry updates
/// and renders the list of received telemetry values.
class _TelemetryLiveWidgetState extends State<TelemetryLiveWidget> {
  /// A subscription to the telemetry stream
  late StreamSubscription<TelemetryData> _subscription;

  /// A list holding received telemetry data, with newest first
  final List<TelemetryData> _dataList = [];

  @override
  void initState() {
    super.initState();

    /// Start listening to the telemetry stream from the socket server.
    /// Filter data so we only listen to telemetry for the selected thingId.
    _subscription = GlobalManager.instance.socketServerManager.telemetryStream
        .listen((data) {
          if (data.thingId == widget.thingId) {
            setState(() {
              /// Insert new telemetry data at the top of the list
              _dataList.insert(0, data);
            });
          }
        });
  }

  @override
  void dispose() {
    /// Cancel the stream subscription when the widget is destroyed
    _subscription.cancel();
    super.dispose();
  }

  @override
  // ignore: prefer_expression_function_bodies
  Widget build(BuildContext context) {
    /// Build a fixed-size widget that displays a scrollable list of telemetry entries
    return SizedBox(
      width: 300,
      height: 300,
      child: ListView.builder(
        itemCount: _dataList.length,
        itemBuilder: (context, index) {
          final data = _dataList[index];
          return ListTile(
            /// Show the telemetry type and value as the main title
            title: Text('${data.type}: ${data.value}'),

            /// Show the timestamp (converted to local time) as the subtitle
            subtitle: Text(data.timestamp.toLocal().toString()),
          );
        },
      ),
    );
  }
}
