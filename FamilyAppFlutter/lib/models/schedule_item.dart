import 'package:uuid/uuid.dart';

/// Model representing a repeating or one-off schedule entry.
class ScheduleItem {
  final String id;
  final String title;
  final String? description;
  final DateTime startDateTime;
  // Optional end date/time for a schedule entry.
  final DateTime? endDateTime;
  final List<String>? memberIds;
  final String? type;
  final DateTime updatedAt;

  ScheduleItem({
    String? id,
    required this.title,
    this.description,
    required this.startDateTime,
    this.endDateTime,
    this.memberIds,
    this.type,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'memberIds': memberIds,
      'type': type,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ScheduleItem fromMap(Map<String, dynamic> map) {
    // Helper to parse various timestamp formats into a DateTime.
    DateTime parse(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    }

    return ScheduleItem(
      id: map['id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      startDateTime: parse(map['startDateTime']),
      endDateTime:
          map['endDateTime'] != null ? parse(map['endDateTime']) : null,
      memberIds:
          (map['memberIds'] as List?)?.map((e) => e.toString()).toList(),
      type: map['type'] as String?,
      updatedAt: parse(map['updatedAt']),
    );
  }
}
