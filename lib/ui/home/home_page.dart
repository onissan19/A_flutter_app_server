import 'package:flutter/material.dart';
import 'package:flutter_app_server/managers/global_manager.dart';
import 'package:flutter_app_server/models/thing.dart';
import 'package:flutter_app_server/models/app_mobile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Tu peux mettre ici un appel pour initialiser ou récupérer des données.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: theme.colorScheme.inversePrimary, title: Text(widget.title)),
      body: Column(
        children: [
          // Première partie : Liste des Things
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<List<Thing>>(
                stream: GlobalManager.instance.thingsManager.thingsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final things = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Things',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: things.length,
                          itemBuilder: (context, index) {
                            final thing = things[index];
                            return ListTile(
                              title: Text(thing.id),
                              subtitle: Text('Type: ${thing.type}, Registered: ${thing.isRegistered}'),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Deuxième partie : Liste des AppMobiles
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<List<AppMobile>>(
                stream: GlobalManager.instance.appMobileManager.appsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final apps = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AppMobiles',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: apps.length,
                          itemBuilder: (context, index) {
                            final app = apps[index];
                            return ListTile(
                              title: Text(app.name),
                              subtitle: Text('ID: ${app.id}, Auth: ${app.isAuth}'),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action flottante pour nettoyer les listes ou toute autre fonctionnalité
        },
        tooltip: 'Clear',
        child: const Icon(Icons.clear),
      ),
    );
  }
}
