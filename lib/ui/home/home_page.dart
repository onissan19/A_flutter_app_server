import 'dart:async';
import 'package:flutter_app_server/managers/global_manager.dart';
import 'package:flutter_app_server/models/thing.dart';
import 'package:flutter/material.dart';

/// Home page of the app
class HomePage extends StatefulWidget {
  /// Title of the home page
  const HomePage({super.key, required this.title});

  /// Title of the home page
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State of the home page
class _HomePageState extends State<HomePage> {
  /// List of Things
  List<Thing> _things = [];

  /// Default constructor
  _HomePageState();

  @override
  void initState() {
    super.initState();
    _fetchThings();
  }

  // Fonction pour récupérer les Things depuis le ThingsManager
  Future<void> _fetchThings() async {
    // Utiliser ThingsManager pour récupérer les objets de la base de données
    List<Thing> things = await GlobalManager.instance.thingsManager.getAllThingsFromDatabase();
    setState(() {
      _things = things; // Mettre à jour l'état avec la liste des Things
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: theme.colorScheme.inversePrimary, title: Text(widget.title)),
      body: ListView.builder(
        itemCount: _things.length,
        itemBuilder: (context, index) {
          final thing = _things[index];
          return ListTile(
            title: Text(thing.id), // Vous pouvez afficher d'autres propriétés selon votre modèle
            subtitle: Text('Type: ${thing.type}, Registered: ${thing.isRegistered}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          _things.clear(); // Clear the list
        }),
        tooltip: 'Clear',
        child: const Icon(Icons.clear),
      ),
    );
  }
}
