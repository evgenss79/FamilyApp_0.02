import 'package:uuid/uuid.dart';

/// Model representing a repeating or one‑off schedule entry.
///
/// A schedule item describes a block of time reserved for a particular activity.
/// It may be associated with one or more family members via their identifiers,
/// and can optionally specify a type to help with filtering (e.g. 'School',
/// 'Work', 'Hobby').
class ScheduleItem {
  /// Unique identifier for the schedule item.
  final String id;

  /// Title or short description of the activity (e.g. "Piano lesson").
  final String title;

  /// Optional longer description for additional details.
  final String? description;

  /// Starting date/time of the schedule entry.
  final DateTime startDateTime;

  /// Optional end date/time of the schedule entry. When null, the item is
  /// considered to have no explicit end (e.g. a reminder).
  final DateTime? endDateTime;

  /// Optional list of member identifiers who are associated with this item.
  /// If null, the entry applies to the whole family.
  final List<String>? memberIds;

  /// Optional type of the schedule entry, useful for filtering (e.g. 'School',
  /// 'Work', 'Sport', etc.).
  final String? type;

  ScheduleItem({
    String? id,
    required this.title,
    this.description,
    required this.startDateTime,
    this.endDateTime,
    this.memberIds,
    this.type,
  }) : id = id ?? const Uuid().v4();

  /// Serialize this schedule item into a map for storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'memberIds': memberIds,
      'type': type,
    };
  }

  /// Create a ScheduleItem instance from a map. Expects ISO8601 strings for
  /// date/time fields and a list of strings for the member identifiers.
  static ScheduleItem fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      startDateTime: DateTime.parse(map['startDateTime'] as String),
      endDateTime: map['endDateTime'] != null
          ? DateTime.parse(map['endDateTime'] as String)
          : null,
      memberIds: (map['memberIds'] as List?)?.map((e) => e as String).toList(),
      type: map['type'] as String?,
    );
  }
}