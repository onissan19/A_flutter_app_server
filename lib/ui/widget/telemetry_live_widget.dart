import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_server/models/telemetry_data.dart';
import 'package:flutter_app_server/managers/global_manager.dart';

class TelemetryLiveWidget extends StatefulWidget {
  final String thingId;

  const TelemetryLiveWidget({Key? key, required this.thingId})
    : super(key: key);

  @override
  State<TelemetryLiveWidget> createState() => _TelemetryLiveWidgetState();
}

class _TelemetryLiveWidgetState extends State<TelemetryLiveWidget> {
  late StreamSubscription<TelemetryData> _subscription;
  final List<TelemetryData> _dataList = [];

  @override
  void initState() {
    super.initState();
    _subscription = GlobalManager.instance.socketServerManager.telemetryStream
        .listen((data) {
          if (data.thingId == widget.thingId) {
            setState(() {
              _dataList.insert(0, data); // ajoute en haut de la liste
            });
          }
        });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: ListView.builder(
        itemCount: _dataList.length,
        itemBuilder: (context, index) {
          final data = _dataList[index];
          return ListTile(
            title: Text('${data.type}: ${data.value}'),
            subtitle: Text(data.timestamp.toLocal().toString()),
          );
        },
      ),
    );
  }
}
