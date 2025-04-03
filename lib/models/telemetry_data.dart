class TelemetryData {
  int id;
  // ignore: public_member_api_docs
  String thingId;
  // ignore: public_member_api_docs
  String type;
  // ignore: public_member_api_docs
  String value;
  // ignore: public_member_api_docs
  DateTime timestamp;

  // ignore: public_member_api_docs
  TelemetryData({
    required this.id,
    required this.thingId,
    required this.type,
    required this.value,
    required this.timestamp,
  });

  // Convertir en Map pour l'enregistrement en base de données
  // ignore: public_member_api_docs
  Map<String, Object?> toMap() => {
      'id': id,
      'thingId': thingId,
      'type': type,
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch, // Stocké en tant qu'entier
    };

  // Créer un objet depuis un Map (récupération depuis la base de données)
  factory TelemetryData.fromMap(Map<String, Object?> map) => TelemetryData(
      id: map['id']! as int,
      thingId: map['thingId']! as String,
      type: map['type']! as String,
      value: map['value']! as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
    );

  @override
  String toString() => 'TelemetryData{id: $id, thingId: $thingId, type: $type, value: $value, timestamp: $timestamp}';
}
