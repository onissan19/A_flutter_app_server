import 'package:flutter/material.dart';
import 'package:flutter_app_server/managers/global_manager.dart';
import 'package:flutter_app_server/models/thing.dart';
import 'package:flutter_app_server/models/app_mobile.dart';
import 'package:flutter_app_server/models/http_log.dart';
import 'package:flutter_app_server/ui/widget/telemetry_live_widget.dart';

/// The main home page widget containing tabs for:
/// - Connected/Non-connected Things
/// - Connected/Non-connected Mobile Apps
/// - Real-time HTTP Logs
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State class for HomePage which manages tabs and live data updates.
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Currently selected log level for filtering logs.
  String _selectedLogLevel = 'All';

  /// Full list of received HTTP logs.
  final List<HttpLog> _logs = [];

  /// Current list of connected Things.
  List<Thing> things = [];

  /// Current list of connected mobile apps.
  List<AppMobile> appMobiles = [];

  @override
  void initState() {
    super.initState();

    /// Initialize tab controller with 3 tabs.
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    /// Listen to live HTTP logs and add them to the local list.
    GlobalManager.instance.httpLoggingManager.logStream.listen((log) {
      setState(() {
        _logs.add(log);
      });
    });

    /// Listen for connected Things updates.
    GlobalManager.instance.thingsManager.thingsStream.listen((Things) {
      setState(() {
        things = Things;
      });
    });

    /// Listen for connected mobile apps updates.
    GlobalManager.instance.appMobileManager.appsStream.listen((AppMobiles) {
      setState(() {
        appMobiles = AppMobiles;
      });
    });
  }

  /// Callback when the tab changes.
  void _onTabChanged() {
    if (_tabController.index == 2) {
      // Currently no extra logic on Logs tab.
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Things"),
            Tab(text: "Apps Mobiles"),
            Tab(text: "Logs"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThingsTab(),
          _buildAppsTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  /// Builds the UI for the Things tab.
  Widget _buildThingsTab() => StreamBuilder<List<Thing>>(
      stream: GlobalManager.instance.thingsManager.thingsStream,
      builder: (context, connectedSnapshot) {
        final connectedThings = things;
        final connectedIds = connectedThings.map((e) => e.id).toSet();

        return FutureBuilder<List<Thing>>(
          future: GlobalManager.instance.databaseHelper.getAllThings(),
          builder: (context, dbSnapshot) {
            if (!dbSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            final allThings = dbSnapshot.data!;
            final nonConnectedThings = allThings.where((thing) => !connectedIds.contains(thing.id)).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Section for connected Things
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Connected", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (connectedThings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("No connected devices."),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: connectedThings.length,
                      itemBuilder: (context, index) =>
                          _buildThingItem(connectedThings[index], withActions: true),
                    ),

                  /// Section for non-connected Things
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Not Connected", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (nonConnectedThings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("No stored unconnected devices."),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: nonConnectedThings.length,
                      itemBuilder: (context, index) =>
                          _buildThingItem(nonConnectedThings[index], withActions: false),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

  /// Builds the UI for the Apps Mobiles tab.
  Widget _buildAppsTab() => StreamBuilder<List<AppMobile>>(
      stream: GlobalManager.instance.appMobileManager.appsStream,
      builder: (context, connectedSnapshot) {
        final connectedApps = connectedSnapshot.data ?? [];
        final connectedIds = connectedApps.map((e) => e.id).toSet();

        return FutureBuilder<List<AppMobile>>(
          future: GlobalManager.instance.databaseHelper.getAllApps(),
          builder: (context, dbSnapshot) {
            if (!dbSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            final allApps = dbSnapshot.data!;
            final nonConnectedApps = allApps.where((app) => !connectedIds.contains(app.id)).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Section for connected apps
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Connected", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (connectedApps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("No connected apps."),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: connectedApps.length,
                      itemBuilder: (context, index) =>
                          _buildAppItem(connectedApps[index], withActions: true),
                    ),

                  /// Section for non-connected apps
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Not Connected", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (nonConnectedApps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("No stored unconnected apps."),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: nonConnectedApps.length,
                      itemBuilder: (context, index) =>
                          _buildAppItem(nonConnectedApps[index], withActions: false),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

  /// Builds the UI for the Logs tab, including a dropdown filter and a list of logs.
  Widget _buildLogsTab() => Column(
      children: [
        /// Dropdown to filter log levels
        Padding(
          padding: const EdgeInsets.all(8),
          child: DropdownButton<String>(
            value: _selectedLogLevel,
            onChanged: (String? newValue) {
              setState(() {
                _selectedLogLevel = newValue!;
              });
            },
            items: <String>['All', 'info', 'warning', 'error']
                .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              )).toList(),
          ),
        ),
        /// Display filtered logs
        Expanded(
          child: ListView.builder(
            itemCount: _filteredLogs.length,
            itemBuilder: (context, index) {
              final log = _filteredLogs[index];

              /// Color the log based on severity level
              Color logColor;
              if (log.logLevel.name == 'info') {
                logColor = Colors.blue;
              } else if (log.logLevel.name == "warning") {
                logColor = Colors.orange;
              } else if (log.logLevel.name == "error") {
                logColor = Colors.red;
              } else {
                logColor = Colors.black;
              }

              return ListTile(
                tileColor: logColor.withOpacity(0.1),
                title: Text(
                  log.formattedLogMsg,
                  style: TextStyle(color: logColor),
                ),
                subtitle: Text('${log.logLevel.name} - ${log.timestamp.toLocal()}'),
              );
            },
          ),
        ),
      ],
    );

  /// Filters the logs list based on selected log level.
  List<HttpLog> get _filteredLogs {
    List<HttpLog> filteredLogs = [];

    if (_selectedLogLevel == "All") {
      filteredLogs = _logs;
    } else {
      filteredLogs = _logs.where((log) => log.logLevel.name == _selectedLogLevel).toList();
    }

    return filteredLogs.reversed.toList();
  }

  /// Builds a list tile for a Thing with optional actions.
  Widget _buildThingItem(Thing thing, {required bool withActions}) => Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: Text(thing.type, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: withActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// View telemetry
                  IconButton(
                    icon: const Icon(Icons.bar_chart, color: Colors.blue),
                    tooltip: 'View Telemetry',
                    onPressed: () => _showTelemetryModal(context, thing),
                  ),
                  /// Disconnect
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.red),
                    onPressed: () => _disconnectThing(thing.id),
                  ),
                  /// Delete
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteThing(thing.id),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteThing(thing.id),
              ),
      ),
    );

  /// Builds a list tile for a Mobile App with optional actions.
  Widget _buildAppItem(AppMobile app, {required bool withActions}) => Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: withActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Disconnect
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.red),
                    onPressed: () => _disconnectApp(app.id),
                  ),
                  /// Delete
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteApp(app.id),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteApp(app.id),
              ),
      ),
    );

  /// Disconnects a Thing by its ID.
  void _disconnectThing(String id) {
    GlobalManager.instance.socketServerManager.disconnectClient(id);
    GlobalManager.instance.thingsManager.disconnectThing(id);
    setState(() {});
  }

  /// Deletes a Thing by its ID.
  void _deleteThing(String id) {
    GlobalManager.instance.thingsManager.unregisterThing(id);
    setState(() {});
  }

  /// Disconnects an App by its ID.
  void _disconnectApp(String id) {
    GlobalManager.instance.socketServerManager.disconnectClient(id);
    GlobalManager.instance.appMobileManager.disconnectApp(id);
    setState(() {});
  }

  /// Deletes an App by its ID.
  void _deleteApp(String id) {
    GlobalManager.instance.appMobileManager.unregisterApp(id);
    setState(() {});
  }

  /// Shows a modal dialog with telemetry data for a given Thing.
  void _showTelemetryModal(BuildContext context, Thing thing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          title: Text('Telemetry of ${thing.id}'),
          content: TelemetryLiveWidget(thingId: thing.id),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
    );
  }
}
