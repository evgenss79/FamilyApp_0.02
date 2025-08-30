import 'package:uuid/uuid.dart';

/// Model representing a family event or appointment.
class Event {
  /// Unique identifier for the event.
  final String id;

  /// Title summarizing the event.
  final String title;

  /// Start date and time of the event.
  ///
  /// In earlier versions of the app only a single `date` field was stored. To
  /// maintain backwards compatibility, this field will be populated from
  /// `date` if `startDateTime` is not present in persisted data.
  final DateTime startDateTime;

  /// End date and time of the event. If no distinct end time is provided the
  /// end time will match the start time.
  final DateTime endDateTime;

  /// Optional description or details about the event.
  final String? description;

  /// IDs of participants involved in the event.
  final List<String> participantIds;

  /// Construct a new [Event]. Both [startDateTime] and [endDateTime] must be
  /// provided; if they are equal, the event represents a single moment in
  /// time. The [id] will be automatically generated if omitted.
  Event({
    String? id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    List<String>? participantIds,
  })  : id = id ?? Uuid().v4(),
        participantIds = participantIds ?? <String>[];

  /// Convert this event into a map for storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDateTime': startDateTime.millisecondsSinceEpoch,
      'endDateTime': endDateTime.millisecondsSinceEpoch,
      'description': description,
      'participantIds': participantIds,
    };
  }

  /// Create an event instance from a map. This will also handle backwards
  /// compatibility with older versions of the app where a single `date` field
  /// was used.
  factory Event.fromMap(Map<String, dynamic> map) {
    final startDateMillis = map['startDateTime'] as int?;
    final endDateMillis = map['endDateTime'] as int?;
    // When startDateTime is absent, `date` (a DateTime) is expected.
    final startDateTime = startDateMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(startDateMillis)
        : (map['date'] as DateTime);
    final endDateTime = endDateMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(endDateMillis)
        : startDateTime;
    final participantsDynamic = map['participantIds'] as List<dynamic>?;
    final participantIds = participantsDynamic?.cast<String>() ?? <String>[];
    return Event(
      id: map['id'] as String?,
      title: map['title'] as String,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      description: map['description'] as String?,
      participantIds: participantIds,
    );
  }
}
