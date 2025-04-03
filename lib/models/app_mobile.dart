/// models/app_mobile.dart
class AppMobile {
  String id;
  String name;
  String appKey;
  bool isAuth;
  DateTime timestamp;

  AppMobile({
    required this.id,
    required this.name,
    required this.appKey,
    required this.isAuth,
    required this.timestamp,
  });

  /// Convertit l'objet en Map pour la base de données
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'app_key': appKey,
        'isAuth': isAuth ? 1 : 0,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Convertit un Map en objet AppMobile avec un cast explicite
  factory AppMobile.fromMap(Map<String, dynamic> map) {
    return AppMobile(
      id: map['id'] as String,
      name: map['name'] as String,
      appKey: map['app_key'] as String,
      isAuth: (map['isAuth'] as int) == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
