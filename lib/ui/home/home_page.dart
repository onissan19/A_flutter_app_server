import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_server/managers/global_manager.dart';
import 'package:flutter_app_server/models/thing.dart';
import 'package:flutter_app_server/models/app_mobile.dart';
import 'package:flutter_app_server/models/http_log.dart';
import 'package:flutter_app_server/ui/widget/telemetry_live_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLogLevel = 'All';
  final List<HttpLog> _logs = []; // Variable pour stocker les logs
  List<Thing> things=[];
  List<AppMobile> appMobiles=[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Écoute des logs et mise à jour de la liste des logs
    GlobalManager.instance.httpLoggingManager.logStream.listen((log) {
      setState(() {
        _logs.add(log); // Ajouter un nouveau log à la liste
      });
    });
    GlobalManager.instance.thingsManager.thingsStream.listen((Things) {
      setState(() {
        things =Things; // Ajouter un nouveau log à la liste
      });
    });

    GlobalManager.instance.appMobileManager.appsStream.listen((AppMobiles) {
      setState(() {
        appMobiles =AppMobiles; // Ajouter un nouveau log à la liste
      });
    });
  }

  // Fonction appelée lors du changement d'onglet
  void _onTabChanged() {
    if (_tabController.index == 2) {
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

  Widget _buildThingsTab() {
    return StreamBuilder<List<Thing>>(
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
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Connectés", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (connectedThings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Aucun élément connecté."),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: connectedThings.length,
                      itemBuilder: (context, index) =>
                          _buildThingItem(connectedThings[index], withActions: true),
                    ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Non Connectés", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (nonConnectedThings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Aucun élément non connecté en base."),
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
  }

  Widget _buildAppsTab() {
    return StreamBuilder<List<AppMobile>>(
      stream: GlobalManager.instance.appMobileManager.appsStream,
      builder: (context, connectedSnapshot) {
        final connectedApps = connectedSnapshot.data ?? [];
        final connectedIds = connectedApps.map((e) => e.id).toSet();

        return FutureBuilder<List<AppMobile>>(
          future: GlobalManager.instance.databaseHelper.getAllApps(),
          builder: (context, dbSnapshot) {
            if (!dbSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            final allApps = dbSnapshot.data!;
            final nonConnectedApps =
                allApps.where((app) => !connectedIds.contains(app.id)).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Connectées", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (connectedApps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Aucune application connectée."),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: connectedApps.length,
                      itemBuilder: (context, index) =>
                          _buildAppItem(connectedApps[index], withActions: true),
                    ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Non Connectées", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  if (nonConnectedApps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Aucune application non connectée en base."),
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
  }

  Widget _buildLogsTab() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: DropdownButton<String>(
          value: _selectedLogLevel,
          onChanged: (String? newValue) {
            setState(() {
              _selectedLogLevel = newValue!;
            });
          },
          items: <String>['All', 'Level.info', 'Level.warning', 'Level.error']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
      // Utilisation de Expanded pour éviter la taille infinie
      Expanded(
        child: ListView.builder(
          itemCount: _filteredLogs.length,
          itemBuilder: (context, index) {
            final log = _filteredLogs[index];

            // Définition de la couleur en fonction du niveau de log
            Color logColor;
            if (log.logLevel.toString() == 'Level.info') {
              logColor = Colors.blue;
            } else if (log.logLevel.toString() == "Level.warning") {
              logColor = Colors.orange;
            } else if (log.logLevel.toString() == "Level.error") {
              logColor = Colors.red;
            } else {
              logColor = Colors.black; // Par défaut, si aucun niveau spécifique
            }

            return ListTile(
              tileColor: logColor.withOpacity(0.1), // Applique une couleur de fond avec opacité
              title: Text(
                log.formattedLogMsg,
                style: TextStyle(
                  color: logColor, // Change la couleur du texte en fonction du niveau
                ),
              ),
              subtitle: Text('${log.logLevel.toString()} - ${log.timestamp.toLocal()}'),
            );
          },
        ),
      ),
    ],
  );
}


  // Retourne les logs filtrés en fonction du niveau sélectionné
  List<HttpLog> get  _filteredLogs {
  List<HttpLog> filteredLogs = [];
  
  if (_selectedLogLevel == "All") {
    filteredLogs = _logs;
  } else {
    filteredLogs = _logs.where((log) => log.logLevel.toString() == _selectedLogLevel).toList();
  }

  // Inverse l'ordre des logs pour afficher le plus récent en premier
  return filteredLogs.reversed.toList();
}

  Widget _buildThingItem(Thing thing, {required bool withActions}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: Text(thing.type, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: withActions
    ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.blue),
            tooltip: 'Voir télémetrie',
            onPressed: () => _showTelemetryModal(context, thing),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.red),
            onPressed: () => _disconnectThing(thing.id),
          ),
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
  }

  Widget _buildAppItem(AppMobile app, {required bool withActions}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: withActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.red),
                    onPressed: () => _disconnectApp(app.id),
                  ),
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
  }

  void _disconnectThing(String id) {
    GlobalManager.instance.socketServerManager.disconnectClient(id);
    GlobalManager.instance.thingsManager.disconnectThing(id);
    setState(() {});
  }

  void _deleteThing(String id) {
    GlobalManager.instance.thingsManager.unregisterThing(id);
    setState(() {});
  }

  void _disconnectApp(String id) {
    GlobalManager.instance.socketServerManager.disconnectClient(id);
    GlobalManager.instance.appMobileManager.disconnectApp(id);
    setState(() {});
  }

  void _deleteApp(String id) {
    GlobalManager.instance.appMobileManager.unregisterApp(id);
    setState(() {});
  }

  void _showTelemetryModal(BuildContext context, Thing thing) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Télémétrie de ${thing.id}'),
        content: TelemetryLiveWidget(thingId: thing.id),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      );
    },
  );
}

}
