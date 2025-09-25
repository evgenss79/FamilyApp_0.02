import '../utils/parsing.dart';

/// Represents a member of the family with optional contact information,
/// hobbies and custom metadata.
class FamilyMember {
  static const Object _sentinel = Object();

  const FamilyMember({
    required this.id,
    this.familyId,
    this.userId,
    this.name,
    this.relationship,
    this.birthday,
    this.phone,
    this.email,
    this.avatarUrl,
    this.avatarStoragePath,
    this.socialMedia,
    this.hobbies,
    this.documents,
    this.documentsList,
    this.socialNetworks,
    this.messengers,
    this.fcmTokens,
    this.isAdmin = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? familyId;
  final String? userId;
  final String? name;
  final String? relationship;
  final DateTime? birthday;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? avatarStoragePath;
  final String? socialMedia;
  final String? hobbies;
  final String? documents;
  final List<Map<String, String>>? documentsList;
  final List<Map<String, String>>? socialNetworks;
  final List<Map<String, String>>? messengers;
  final List<String>? fcmTokens;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: (map['id'] ?? '').toString(),
      familyId: map['familyId'] as String?,
      userId: map['userId'] as String?,
      name: map['name'] as String?,
      relationship: map['relationship'] as String?,
      birthday: parseNullableDateTime(map['birthday']),
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      avatarStoragePath: map['avatarStoragePath'] as String?,
      socialMedia: map['socialMedia'] as String?,
      hobbies: map['hobbies'] as String?,
      documents: map['documents'] as String?,
      documentsList: parseStringMapList(map['documentsList']),
      socialNetworks: parseStringMapList(map['socialNetworks']),
      messengers: parseStringMapList(map['messengers']),
      fcmTokens: (map['fcmTokens'] as List?)
          ?.whereType<String>()
          .toList(growable: false),
      isAdmin: map['isAdmin'] as bool? ?? false,
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'familyId': familyId,
        'userId': userId,
        'name': name,
        'relationship': relationship,
        'birthday': birthday?.toIso8601String(),
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
        'avatarStoragePath': avatarStoragePath,
        'socialMedia': socialMedia,
        'hobbies': hobbies,
        'documents': documents,
        'documentsList': documentsList,
        'socialNetworks': socialNetworks,
        'messengers': messengers,
        'fcmTokens': fcmTokens,
        'isAdmin': isAdmin,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  FamilyMember copyWith({
    Object? familyId = _sentinel,
    Object? userId = _sentinel,
    Object? name = _sentinel,
    Object? relationship = _sentinel,
    Object? birthday = _sentinel,
    Object? phone = _sentinel,
    Object? email = _sentinel,
    Object? avatarUrl = _sentinel,
    Object? avatarStoragePath = _sentinel,
    Object? socialMedia = _sentinel,
    Object? hobbies = _sentinel,
    Object? documents = _sentinel,
    Object? documentsList = _sentinel,
    Object? socialNetworks = _sentinel,
    Object? messengers = _sentinel,
    Object? fcmTokens = _sentinel,
    Object? isAdmin = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return FamilyMember(
      id: id,
      familyId: familyId == _sentinel ? this.familyId : familyId as String?,
      userId: userId == _sentinel ? this.userId : userId as String?,
      name: name == _sentinel ? this.name : name as String?,
      relationship: relationship == _sentinel
          ? this.relationship
          : relationship as String?,
      birthday: birthday == _sentinel ? this.birthday : birthday as DateTime?,
      phone: phone == _sentinel ? this.phone : phone as String?,
      email: email == _sentinel ? this.email : email as String?,
      avatarUrl: avatarUrl == _sentinel ? this.avatarUrl : avatarUrl as String?,
      avatarStoragePath: avatarStoragePath == _sentinel
          ? this.avatarStoragePath
          : avatarStoragePath as String?,
      socialMedia:
          socialMedia == _sentinel ? this.socialMedia : socialMedia as String?,
      hobbies: hobbies == _sentinel ? this.hobbies : hobbies as String?,
      documents: documents == _sentinel ? this.documents : documents as String?,
      documentsList: documentsList == _sentinel
          ? this.documentsList
          : documentsList as List<Map<String, String>>?,
      socialNetworks: socialNetworks == _sentinel
          ? this.socialNetworks
          : socialNetworks as List<Map<String, String>>?,
      messengers: messengers == _sentinel
          ? this.messengers
          : messengers as List<Map<String, String>>?,
      fcmTokens:
          fcmTokens == _sentinel ? this.fcmTokens : fcmTokens as List<String>?,
      isAdmin: isAdmin == _sentinel ? this.isAdmin : isAdmin as bool,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}
