import 'package:family_app_flutter/utils/parsing.dart';

class Friend {
  /// Unique identifier for the friend.
  final String? id;

  /// Display name of the friend.
  final String? name;

  Friend({this.id, this.name});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };

  static Friend fromDecodableMap(Map<String, dynamic> map) {
    return Friend(
      id: (map['id'] ?? '').toString(),
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }
}

