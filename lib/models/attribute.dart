/// models/attribute.dart
class Attribute {
  ///Peut être un Thing ID ou un App ID
  String ownerId;
  ///
  String name;
  ///
  String value;
  ///
  bool isForApp; // Indique si l'attribut est pour une application ou un objet
///
  Attribute({
    required this.ownerId,
    required this.name,
    required this.value,
    required this.isForApp,
  });
}
