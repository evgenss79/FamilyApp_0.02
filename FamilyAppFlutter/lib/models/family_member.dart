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
    /// Optional URL of the member's avatar image.
  final String? avatarUrl;


  /// Optional social media handles or links.
  final String? socialMedia;

  /// Optional hobbies description.
  final String? hobbies;

  /// Optional documents or notes.
  final String? documents;

  /// Optional list of structured documents.  Each entry is a map with
  /// a 'type' key specifying the document type (e.g. 'Passport', 'ID') and
  /// a 'value' key containing the identifier or link.  This is preferred over
  /// the legacy [documents] string when available.  May be null if no
  /// documents are recorded or loaded from older app versions.
  final List<Map<String, String>>? documentsList;

  /// Optional list of social network profiles.  Each entry contains a
  /// 'type' (e.g. 'Instagram', 'Facebook') and a 'value' with the full URL
  /// or handle.  Supersedes the legacy [socialMedia] string when populated.
  final List<Map<String, String>>? socialNetworks;

  /// Optional list of messenger contacts.  Each entry has a 'type'
  /// (e.g. 'WhatsApp', 'Telegram') and a 'value' with the contact
  /// identifier.  If null, no messenger contacts are recorded.
  final List<Map<String, String>>? messengers;

  FamilyMember({
    String? id,
    required this.name,
    required this.relationship,
    this.birthday,
    this.phone,
    this.email,
    
      this.avatarUrl,
  this.socialMedia,

    this.hobbies,
    
    
    this.documents,
      

    this.documentsList,
    this.socialNetworks,
    this.messengers,
  }) : id = id ?? const Uuid().v4();

  /// Convert object to a map for persistence.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'birthday': birthday?.toIso8601String(),
        'phone': phone,
        'email': email,
      'avatarUrl': avatarUrl,
        // Persist both the legacy socialMedia string and the structured list.
        'socialMedia': socialMedia,
        'socialNetworks': socialNetworks,
        'hobbies': hobbies,
        // Persist both the legacy documents string and the structured list.
        'documents': documents,
        'documentsList': documentsList,
        'messengers': messengers,
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
             avatarUrl: map['avatarUrl'] as String?,


        socialMedia: map['socialMedia'] as String?,
        hobbies: map['hobbies'] as String?,
        documents: map['documents'] as String?,
        documentsList: (map['documentsList'] as List?)?.map<Map<String, String>>((e) => Map<String, String>.from(e as Map)).toList(),
        socialNetworks: (map['socialNetworks'] as List?)?.map<Map<String, String>>((e) => Map<String, String>.from(e as Map)).toList(),
        messengers: (map['messengers'] as List?)?.map<Map<String, String>>((e) => Map<String, String>.from(e as Map)).toList(),
      );
}
