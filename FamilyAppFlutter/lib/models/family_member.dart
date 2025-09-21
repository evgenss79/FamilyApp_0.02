class FamilyMember {
  final String id;
  final String? name;
  final String? relationship;
  final DateTime? birthday;
  final String? phone;
  final String? email;
  final String? avatarUrl;
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
}
