
import 'package:flutter_app_server/models/attribute.dart';

class Thing {
  String id;
  String type;
  String? apiKey;
  bool isRegistered;
  List<Attribute> attributes; // Liste non enregistrée dans la base
  DateTime timestamp;

  // Constructeur
  Thing({
    required this.id,
    required this.type,
    this.apiKey,
    this.isRegistered = false,
    List<Attribute>? attributes,
    required this.timestamp,
  }) : attributes = attributes ?? [];

  // Méthode toMap() pour convertir l'objet en Map sans la liste d'attributs
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type,
      'apiKey': apiKey,
      'isRegistered': isRegistered ? 1 : 0,  // SQLite ne supporte pas directement le booléen
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Méthode fromMap() pour créer un objet Thing à partir d'un Map
  factory Thing.fromMap(Map<String, Object?> map) {
    return Thing(
      id: map['id'] as String,
      type: map['type'] as String,
      apiKey: map['apiKey'] as String?,
      isRegistered: (map['isRegistered'] as int) == 1,
      attributes: [], // On ignore les attributes ici
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
    );
  }

  @override
  String toString() {
    return 'Thing{id: $id, type: $type, apiKey: $apiKey, isRegistered: $isRegistered}';
  }
}
