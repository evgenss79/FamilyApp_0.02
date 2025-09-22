class FamilyMember {
  static const _sentinel = Object();

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

  FamilyMember({
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
  });

  Map<String, dynamic> toMap() => {
        'id': id,
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

  static FamilyMember fromMap(Map<String, dynamic> m) => FamilyMember(
        id: (m['id'] ?? '').toString(),
        name: m['name'] as String?,
        relationship: m['relationship'] as String?,
        birthday: (m['birthday'] is String && (m['birthday'] as String).isNotEmpty)
            ? DateTime.tryParse(m['birthday'] as String)
            : null,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        avatarUrl: m['avatarUrl'] as String?,
        avatarStoragePath: m['avatarStoragePath'] as String?,
        socialMedia: m['socialMedia'] as String?,
        hobbies: m['hobbies'] as String?,
        documents: m['documents'] as String?,
        documentsList: (m['documentsList'] as List?)
            ?.whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
            .toList(),
        socialNetworks: (m['socialNetworks'] as List?)
            ?.whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
            .toList(),
        messengers: (m['messengers'] as List?)
            ?.whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
            .toList(),
      );

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
  }) {
    return FamilyMember(
      id: id,
      name: name == _sentinel ? this.name : name as String?,
      relationship:
          relationship == _sentinel ? this.relationship : relationship as String?,
      birthday: birthday == _sentinel ? this.birthday : birthday as DateTime?,
      phone: phone == _sentinel ? this.phone : phone as String?,
      email: email == _sentinel ? this.email : email as String?,
      avatarUrl:
          avatarUrl == _sentinel ? this.avatarUrl : avatarUrl as String?,
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
    );
  }
}
