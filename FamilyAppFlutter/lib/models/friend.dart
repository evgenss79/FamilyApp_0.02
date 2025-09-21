import 'package:uuid/uuid.dart';

/// Represents a connection with another family.
///
/// A `Friend` holds the name of the other family and an optional access
/// level describing what data they can see. In a real implementation
/// this could contain more fields such as shared events or invitations.
class Friend {
  /// Unique identifier for this friend/family connection.
  final String id;

  /// Display name of the friend or family.
  final String familyName;

  /// Optional description of the access level (e.g. read-only, full).
  final String? accessLevel;

  Friend({String? id, required this.familyName, this.accessLevel})
      : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyName': familyName,
      'accessLevel': accessLevel,
    };
  }

  static Friend fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] as String?,
      familyName: map['familyName'] as String,
      accessLevel: map['accessLevel'] as String?,
    );
  }
}