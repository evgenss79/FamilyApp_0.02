import 'package:uuid/uuid.dart';

/// Model representing a member of the family with extended profile information.
class FamilyMember {
  /// Unique identifier for the member.
  final String id;

  /// Display name of the member.
  final String name;

  /// Relationship to the family (e.g. Mother, Son).
  final String relationship;

  /// Optional birthday for the member.
  final DateTime? birthday;

  /// Optional phone number.
  final String? phone;

  /// Optional email address.
  final String? email;

  /// Optional social media handles or links.
  final String? socialMedia;

  /// Optional hobbies description.
  final String? hobbies;

  /// Optional documents or notes.
  final String? documents;

  FamilyMember({
    String? id,
    required this.name,
    required this.relationship,
    this.birthday,
    this.phone,
    this.email,
    this.socialMedia,
    this.hobbies,
    this.documents,
  }) : id = id ?? const Uuid().v4();

  /// Convert object to a map for persistence.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'birthday': birthday?.toIso8601String(),
        'phone': phone,
        'email': email,
        'socialMedia': socialMedia,
        'hobbies': hobbies,
        'documents': documents,
      };

  /// Construct a FamilyMember from a map.
  static FamilyMember fromMap(Map<String, dynamic> map) => FamilyMember(
        id: map['id'] as String?,
        name: map['name'] as String,
        relationship: map['relationship'] as String,
        birthday: map['birthday'] != null
            ? DateTime.parse(map['birthday'] as String)
            : null,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        socialMedia: map['socialMedia'] as String?,
        hobbies: map['hobbies'] as String?,
        documents: map['documents'] as String?,
      );
}
