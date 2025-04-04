import 'dart:async';
import 'dart:math';
import 'package:flutter_app_server/database/database_helper.dart';
import 'package:flutter_app_server/models/thing.dart';

class ThingsManager {
  // Liste des objets enregistrés
  final List<Thing> registeredThings = [];

  // StreamController pour notifier les changements
  final StreamController<List<Thing>> _thingsStreamController = StreamController.broadcast();

  // Getter pour écouter les changements
  Stream<List<Thing>> get thingsStream => _thingsStreamController.stream;

  // Instance unique du singleton
  static final ThingsManager _instance = ThingsManager._internal();

  // Factory constructeur pour retourner l'instance unique
  factory ThingsManager() {
    return _instance;
  }

  // Constructeur privé pour empêcher l'instanciation en dehors de la classe
  ThingsManager._internal();

  // Génération d'une clé API aléatoire
  String generateApiKey() {
    final random = Random();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }

  // Récupérer un Thing par ID (d'abord dans la liste, sinon dans la base)
  Future<Thing?> getThingById(String id) async {
    for (var thing in registeredThings) {
      if (thing.id == id) {
        return thing;
      }
    }
    return await DatabaseHelper().getThingById(id);
  }

  // Enregistrer un nouvel objet
  Future<bool> registerThing(Thing thing) async {
    if (await DatabaseHelper().getThingById(thing.id) != null) {
      return false; // L'objet est déjà enregistré en base
    }
    await DatabaseHelper().insertThing(thing);
    _notifyListeners(); // Notifier les changements
    return true;
  }

  // Déconnecter un Thing (le retirer de la liste)
  void disconnectThing(String id) {
    registeredThings.removeWhere((thing) => thing.id == id);
    _notifyListeners(); // Notifier les changements
  }

  // Authentification d'un Thing via son ID et sa clé API
  Future<bool> authenticateThing(String id, String apiKey) async {
    final thing = await getThingById(id);
    if (thing != null && thing.apiKey == apiKey) {
      thing.isRegistered = true; // Authentification réussie
      if (!registeredThings.contains(thing)) {
        registeredThings.add(thing);
        _notifyListeners(); //Notifier les changements
      }
      return true;
    }
    return false;
  }

  // Récupérer tous les objets de la base de données
  Future<List<Thing>> getAllThingsFromDatabase() async {
    return await DatabaseHelper().getAllThings();
  }

  // Générer un objet aléatoire
  Thing generateRandomThing() {
    final random = Random();
    return Thing(
      id: 'thing_${random.nextInt(1000)}',
      type: ['sensor', 'device', 'gadget'][random.nextInt(3)],
      apiKey: null,
      isRegistered: false,
      timestamp: DateTime.now(),
    );
  }

  // Remplir la base de données avec des objets aléatoires
  Future<void> populateDatabase(int count) async {
    for (int i = 0; i < count; i++) {
      final thing = generateRandomThing();
      await registerThing(thing);
    }
    _notifyListeners(); // Notifier après ajout en masse
  }

  // Désenregistrer un objet (supprime aussi les télémétries)
  Future<bool> unregisterThing(String id) async {
    final thing = await DatabaseHelper().getThingById(id);
    if (thing == null) return false;

    // Déconnecter d'abord l'objet
    disconnectThing(id);

    // Ensuite, supprimer de la base de données
    await DatabaseHelper().deleteThingWithTelemetry(id);

    _notifyListeners(); //Notifier après suppression
    return true;
  }


   Future<bool> isConnected(String id) async{
    final thing = await getThingById(id);
    if (thing != null) {
      if (registeredThings.contains(thing)) {
        return true;
      }
      return false;
    }
    return false;
  }

  // Récupérer tous les objets connectés
  List<Thing> getConnectedThings() {
    return List.unmodifiable(registeredThings);
  }

  // Afficher tous les objets stockés
  Future<void> printAllThings() async {
    final things = await getAllThingsFromDatabase();
    if (things.isEmpty) {
      print('Aucun Thing enregistré.');
    } else {
      print('Liste des Things enregistrés :');
      for (var thing in things) {
        print(thing);
      }
    }
  }

  // Notifier les abonnés en cas de mise à jour de la liste
  void _notifyListeners() {
    _thingsStreamController.add(List.unmodifiable(registeredThings));
  }

  // Fermer le StreamController quand on n'en a plus besoin
  void dispose() {
    _thingsStreamController.close();
  }
}
