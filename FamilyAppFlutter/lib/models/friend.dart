import '../utils/parsing.dart';

/// Represents a friendly family that the user has connected with.
class Friend {
  static const Object _sentinel = Object();

  const Friend({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'phone': phone,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Friend copyWith({
    Object? name = _sentinel,
    Object? phone = _sentinel,
    Object? notes = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return Friend(
      id: id,
      name: name == _sentinel ? this.name : name as String,
      phone: phone == _sentinel ? this.phone : phone as String?,
      notes: notes == _sentinel ? this.notes : notes as String?,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}
