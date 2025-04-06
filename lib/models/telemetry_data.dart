class TelemetryData {
  /// Unique identifier for the telemetry data
  int id;

  /// Identifier for the related thing
  String thingId;

  /// The type/category of the telemetry data
  String type;

  /// The recorded value for this telemetry data
  String value;

  /// Timestamp representing when the telemetry data was recorded
  DateTime timestamp;

  /// Constructor for the [TelemetryData] class
  TelemetryData({
    required this.id,
    required this.thingId,
    required this.type,
    required this.value,
    required this.timestamp,
  });

  /// Converts this object into a [Map] for database storage
  Map<String, Object?> toMap() => {
        'id': id,
        'thingId': thingId,
        'type': type,
        'value': value,
        'timestamp': timestamp.millisecondsSinceEpoch, // Stored as an integer
      };

  /// Creates a [TelemetryData] object from a [Map] (retrieved from the database)
  factory TelemetryData.fromMap(Map<String, Object?> map) => TelemetryData(
        id: map['id']! as int,
        thingId: map['thingId']! as String,
        type: map['type']! as String,
        value: map['value']! as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
      );

  @override
  /// Returns a string representation of the [TelemetryData] object
  String toString() =>
      'TelemetryData{id: $id, thingId: $thingId, type: $type, value: $value, timestamp: $timestamp}';
}