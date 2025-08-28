import 'package:uuid/uuid.dart';

/// Model representing a member of the family.
class FamilyMember {
  /// Unique identifier for the member.
  final String id;

  /// Display name of the member.
  final String name;

  /// Relationship to the family (e.g. Mother, Son).
  final String relationship;

  /// Optional birthday for the member.
  final DateTime? birthday;

  FamilyMember({
    String? id,
    required this.name,
    required this.relationship,
    this.birthday,
  }) : id = id ?? const Uuid().v4();
}
