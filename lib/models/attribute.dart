/// models/attribute.dart
class Attribute {
  /// Can be a Thing ID or an App ID
  String ownerId;

  /// The name of the attribute
  String name;

  /// The value of the attribute
  String value;

  /// Indicates if the attribute is for an application or an object
  bool isForApp;

  /// Constructor for the [Attribute] class
  Attribute({
    required this.ownerId,
    required this.name,
    required this.value,
    required this.isForApp,
  });
}
