import 'package:uuid/uuid.dart';

class Event {
  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final List<String> participantIds;
  final DateTime updatedAt;

  Event({
    String? id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    List<String>? participantIds,
    DateTime? updatedAt,
  })  : id = id ?? Uuid().v4(),
        participantIds = participantIds ?? <String>[],
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDateTime': startDateTime.millisecondsSinceEpoch,
      'endDateTime': endDateTime.millisecondsSinceEpoch,
      'description': description,
      'participantIds': participantIds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    DateTime _parseStart(dynamic v) {
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.parse(v);
      return DateTime.now();
    }

    DateTime _parseEnd(dynamic v, DateTime fallback) {
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.parse(v);
      if (v is DateTime) return v;
      return fallback;
    }

    DateTime _parseUpdated(dynamic v) {
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    }

    final start = _parseStart(map['startDateTime']);
    final end = _parseEnd(map['endDateTime'], start);

    final participantsDynamic = map['participantIds'] as List<dynamic>?;
    final participants = participantsDynamic?.cast<String>() ?? <String>[];

    return Event(
      id: map['id'] as String?,
      title: map['title'] as String,
      startDateTime: start,
      endDateTime: end,
      description: map['description'] as String?,
      participantIds: participants,
      updatedAt: _parseUpdated(map['updatedAt']),
    );
  }
}
