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
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'birthday': birthday?.toIso8601String(),
  };

  static FamilyMember fromMap(Map<String, dynamic> map) => FamilyMember(
    id: map['id'] as String?,
    name: map['name'] as String,
    relationship: map['relationship'] as String,
    birthday: map['birthday'] != null ? DateTime.parse(map['birthday'] as String) : null,
  );
}
