import 'package:family_app_flutter/utils/parsing.dart';

class FamilyMember {
  static const Object _sentinel = Object();

  const FamilyMember({
    required this.id,
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
    this.createdAt,
    this.updatedAt,
  });

  final String id;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
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
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        ...toEncodableMap(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static FamilyMember fromDecodableMap(Map<String, dynamic> map) {

    return FamilyMember(
      id: (map['id'] ?? '').toString(),
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
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),

    );
  }

  FamilyMember copyWith({
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
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return FamilyMember(
      id: id,
      name: name == _sentinel ? this.name : name as String?,
      relationship:
          relationship == _sentinel ? this.relationship : relationship as String?,
      birthday: birthday == _sentinel ? this.birthday : birthday as DateTime?,
      phone: phone == _sentinel ? this.phone : phone as String?,
      email: email == _sentinel ? this.email : email as String?,
      avatarUrl: avatarUrl == _sentinel ? this.avatarUrl : avatarUrl as String?,
      avatarStoragePath: avatarStoragePath == _sentinel
          ? this.avatarStoragePath
          : avatarStoragePath as String?,
      socialMedia: socialMedia == _sentinel
          ? this.socialMedia
          : socialMedia as String?,
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
      createdAt: createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt: updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}
