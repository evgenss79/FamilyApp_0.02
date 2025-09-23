import 'package:family_app_flutter/utils/parsing.dart';

class Event {
  const Event({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    this.participantIds = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final List<String> participantIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'title': title,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime.toIso8601String(),
        'description': description,
        'participantIds': participantIds,
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        ...toEncodableMap(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static Event fromDecodableMap(Map<String, dynamic> map) {
    return Event(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      startDateTime: parseDateTimeOrNow(map['startDateTime']),
      endDateTime: parseDateTimeOrNow(map['endDateTime']),
      description: map['description'] as String?,
      participantIds: parseStringList(map['participantIds']),
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),

    );
  }
}
