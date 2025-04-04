import 'dart:async';
import 'dart:math';
import 'package:flutter_app_server/database/database_helper.dart';
import 'package:flutter_app_server/models/app_mobile.dart';

class AppMobileManager {
  // Liste des applications authentifiées
  final List<AppMobile> authenticatedApps = [];

  // StreamController pour notifier les changements
  final StreamController<List<AppMobile>> _appsStreamController = StreamController.broadcast();

  // Getter pour écouter les changements
  Stream<List<AppMobile>> get appsStream => _appsStreamController.stream;

  // Constructeur privé pour empêcher l'instanciation directe
  static final AppMobileManager _instance = AppMobileManager._internal();

  // Factory pour accéder à l'instance unique
  factory AppMobileManager() {
    return _instance;
  }

  AppMobileManager._internal();

  // Génération d'une clé d'application aléatoire
  String generateAppKey() {
    final random = Random();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }

  // Récupérer une AppMobile par ID (d'abord en mémoire, sinon en base)
  Future<AppMobile?> getAppById(String id) async {
    for (var app in authenticatedApps) {
      if (app.id == id) {
        return app;
      }
    }
    return await DatabaseHelper().getAppById(id);
  }

  // Enregistrer une nouvelle application mobile
  Future<bool> registerApp(AppMobile app) async {
    if (await getAppById(app.id) != null) {
      return false; // L'application est déjà enregistrée
    }

    app.isAuth = false;
    app.timestamp = DateTime.now();

    await DatabaseHelper().insertAppMobile(app);
    _notifyListeners(); // Notifier les changements

    return true;
  }

 Future<bool> isConnected(String id) async{
    final app = await getAppById(id);
    if (app != null) {
      if (authenticatedApps.contains(app)) {
        return true;
      }
      return false;
    }
    return false;
  }


  // Authentifier une application mobile
  Future<bool> authenticateApp(String id, String appKey) async {
    final app = await getAppById(id);
    if (app != null && app.appKey == appKey) {
      app.isAuth = true;
      if (!authenticatedApps.contains(app)) {
        authenticatedApps.add(app);
        _notifyListeners(); // Notifier les changements
      }
      return true;
    }
    return false;
  }

  // Déconnecter une application mobile (la retirer de la liste des authentifiées)
  void disconnectApp(String id) {
    authenticatedApps.removeWhere((app) => app.id == id);
    _notifyListeners(); //Notifier les changements
  }

  // Désenregistrer une application mobile (supprime aussi les données associées)
  Future<bool> unregisterApp(String id) async {
    final app = await getAppById(id);
    if (app == null) return false;

    // Déconnecter l'application en premier
    disconnectApp(id);

    // Ensuite, supprimer de la base de données
    await DatabaseHelper().deleteAppById(id);

    _notifyListeners(); // Notifier après suppression
    return true;
  }

  // Récupérer toutes les applications mobiles de la base de données
  Future<List<AppMobile>> getAllAppsFromDatabase() async {
    return await DatabaseHelper().getAllApps();
  }

  // Récupérer toutes les applications mobiles connectées
  List<AppMobile> getConnectedApps() {
    return List.unmodifiable(authenticatedApps);
  }

  // Générer une AppMobile aléatoire
  AppMobile generateRandomApp() {
    final random = Random();
    return AppMobile(
      id: 'app_${random.nextInt(1000)}',
      name: 'App ${random.nextInt(100)}',
      appKey: generateAppKey(),
      isAuth: false,
      timestamp: DateTime.now(),
    );
  }

  // Remplir la base avec des applications mobiles aléatoires
  Future<void> populateDatabase(int count) async {
    for (int i = 0; i < count; i++) {
      final app = generateRandomApp();
      await registerApp(app);
    }
    _notifyListeners(); // Notifier après ajout en masse
  }

  // Afficher toutes les applications mobiles enregistrées
  Future<void> printAllApps() async {
    final apps = await getAllAppsFromDatabase();
    if (apps.isEmpty) {
      print('Aucune application enregistrée.');
    } else {
      print('Liste des applications enregistrées :');
      for (var app in apps) {
        print(app);
      }
    }
  }

  // Notifier les abonnés en cas de mise à jour de la liste
  void _notifyListeners() {
    _appsStreamController.add(List.unmodifiable(authenticatedApps));
  }

  // Fermer le StreamController quand on n'en a plus besoin
  void dispose() {
    _appsStreamController.close();
  }
}
