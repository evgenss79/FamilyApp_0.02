import '../utils/parsing.dart';

/// Calendar event shared between family members.
class Event {
  static const Object _sentinel = Object();

  Event({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    List<String>? participantIds,
    this.createdAt,
    this.updatedAt,
  }) : participantIds = List.unmodifiable(participantIds ?? const <String>[]);

  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final List<String> participantIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Event.fromMap(Map<String, dynamic> map) {
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

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime.toIso8601String(),
        'description': description,
        'participantIds': participantIds,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Event copyWith({
    Object? title = _sentinel,
    Object? startDateTime = _sentinel,
    Object? endDateTime = _sentinel,
    Object? description = _sentinel,
    List<String>? participantIds,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return Event(
      id: id,
      title: title == _sentinel ? this.title : title as String,
      startDateTime: startDateTime == _sentinel
          ? this.startDateTime
          : startDateTime as DateTime,
      endDateTime:
          endDateTime == _sentinel ? this.endDateTime : endDateTime as DateTime,
      description: description == _sentinel
          ? this.description
          : description as String?,
      participantIds: participantIds ?? this.participantIds,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }
}
