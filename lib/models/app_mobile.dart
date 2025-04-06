/// models/app_mobile.dart
class AppMobile {
  /// Unique identifier for the mobile application
  String id;

  /// Name of the mobile application
  String name;

  /// Key used for application authentication
  String appKey;

  /// Indicates whether authentication is enabled
  bool isAuth;

  /// Timestamp representing the creation or last update time
  DateTime timestamp;

  /// Constructor for the [AppMobile] class
  AppMobile({
    required this.id,
    required this.name,
    required this.appKey,
    required this.isAuth,
    required this.timestamp,
  });

  /// Converts the [AppMobile] object into a [Map] for database storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'app_key': appKey,
        'isAuth': isAuth ? 1 : 0,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Converts a [Map] into an [AppMobile] object with explicit casting
  factory AppMobile.fromMap(Map<String, dynamic> map) => AppMobile(
      id: map['id'] as String,
      name: map['name'] as String,
      appKey: map['app_key'] as String,
      isAuth: (map['isAuth'] as int) == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
}