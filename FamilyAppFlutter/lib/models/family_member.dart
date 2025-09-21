import 'package:hive/hive.dart';

/// Represents a member of a family.  This model is intentionally kept
/// lightweight to satisfy compile-time dependencies within the app.  A
/// [FamilyMember] may include optional contact details and personal
/// information such as hobbies and relationship to the user.  The
/// properties are nullable to accommodate partially filled records.
@HiveType(typeId: 30)
class FamilyMember extends HiveObject {
  /// Unique identifier for this member.
  @HiveField(0)
  String? id;

  /// The display name of the member.
  @HiveField(1)
  String? name;

  /// Optional list of phone numbers associated with the member.
  @HiveField(2)
  List<String>? phones;

  /// Optional list of email addresses associated with the member.
  @HiveField(3)
  List<String>? emails;

  /// Optional list of hobbies or interests for the member.
  @HiveField(4)
  List<String>? hobbies;

  /// Optional URL to the member's avatar image.
  @HiveField(5)
  String? avatarUrl;

  /// Relationship of the member to the primary user (e.g. "mother", "sibling").
  @HiveField(6)
  String? relationship;

  FamilyMember({
    this.id,
    this.name,
    this.phones,
    this.emails,
    this.hobbies,
    this.avatarUrl,
    this.relationship,
  });
}