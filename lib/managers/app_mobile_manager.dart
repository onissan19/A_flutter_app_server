import 'dart:math';
import 'package:flutter_app_server/database/database_helper.dart';
import 'package:flutter_app_server/models/app_mobile.dart';

class AppMobileManager {
  final List<AppMobile> authenticatedApps = [];

  // Génération d'une clé d'application aléatoire
  String _generateAppKey() {
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

    app.appKey = _generateAppKey();
    app.isAuth = true;
    app.timestamp = DateTime.now();

    await DatabaseHelper().insertAppMobile(app);
    return true;
  }

  // Authentifier une application mobile
  Future<bool> authenticateApp(String id, String appKey) async {
    final app = await getAppById(id);
    if (app != null && app.appKey == appKey) {
      app.isAuth = true;
      if (!authenticatedApps.contains(app)) {
        authenticatedApps.add(app);
      }
      return true;
    }
    return false;
  }

  // Déconnecter une application mobile (la retirer de la liste des authentifiées)
  void disconnectApp(String id) {
    authenticatedApps.removeWhere((app) => app.id == id);
  }

  // Désenregistrer une application mobile (supprime aussi les données associées)
  Future<bool> unregisterApp(String id) async {
    final app = await getAppById(id);
    if (app == null) return false;

    //Déconnecter l'application en premier
    disconnectApp(id);

    //Ensuite, supprimer de la base de données
    await DatabaseHelper().deleteAppById(id);

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
      appKey: '',
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
}
