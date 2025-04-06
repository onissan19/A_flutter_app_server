import 'package:flutter_app_server/models/attribute.dart';

class Thing {
  /// Unique identifier for the thing
  String id;

  /// The type/category of the thing
  String type;

  /// API key associated with the thing (optional)
  String? apiKey;

  /// Indicates whether the thing is registered
  bool isRegistered;

  /// List of attributes (not stored in the database)
  List<Attribute> attributes;

  /// Timestamp for the thing's creation or last update
  DateTime timestamp;

  /// Constructor for the [Thing] class
  Thing({
    required this.id,
    required this.type,
    this.apiKey,
    this.isRegistered = false,
    List<Attribute>? attributes,
    required this.timestamp,
  }) : attributes = attributes ?? [];

  /// Converts the object into a [Map] excluding the list of attributes
  Map<String, Object?> toMap() => {
      'id': id,
      'type': type,
      'apiKey': apiKey,
      'isRegistered': isRegistered ? 1 : 0, // SQLite does not natively support boolean values
      'timestamp': timestamp.millisecondsSinceEpoch,
    };

  /// Creates a [Thing] object from a [Map]
  factory Thing.fromMap(Map<String, Object?> map) => Thing(
      id: map['id'] as String,
      type: map['type'] as String,
      apiKey: map['apiKey'] as String?,
      isRegistered: (map['isRegistered'] as int) == 1,
      attributes: [], // Attributes are ignored during this conversion
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
    );

  @override
  /// Returns a string representation of the [Thing] object
  String toString() => 'Thing{id: $id, type: $type, apiKey: $apiKey, isRegistered: $isRegistered}';
}