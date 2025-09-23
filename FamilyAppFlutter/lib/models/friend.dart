class Friend {
  const Friend({
    required this.id,
    this.name,
    this.phone,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? name;
  final String? phone;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'name': name,
        'phone': phone,
        'notes': notes,
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        ...toEncodableMap(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static Friend fromDecodableMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Friend(
      id: (map['id'] ?? '').toString(),
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }
}
