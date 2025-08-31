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
    // Parse startDateTime from milliseconds, ISO string, or fallback to `date`.
    final dynamic startRaw = map['startDateTime'];
    DateTime startDateTime;
    if (startRaw is int) {
      startDateTime = DateTime.fromMillisecondsSinceEpoch(startRaw);
    } else if (startRaw is String) {
      startDateTime = DateTime.parse(startRaw);
    } else {
      final dynamic legacyDate = map['date'];
      if (legacyDate is String) {
        startDateTime = DateTime.parse(legacyDate);
      } else if (legacyDate is int) {
        startDateTime = DateTime.fromMillisecondsSinceEpoch(legacyDate);
      } else {
        startDateTime = legacyDate as DateTime;
      }
    }

    // Parse endDateTime from milliseconds, ISO string, or default to startDateTime.
    final dynamic endRaw = map['endDateTime'];
    DateTime endDateTime;
    if (endRaw is int) {
      endDateTime = DateTime.fromMillisecondsSinceEpoch(endRaw);
    } else if (endRaw is String) {
      endDateTime = DateTime.parse(endRaw);
    } else if (endRaw is DateTime) {
      endDateTime = endRaw;
    } else {
      endDateTime = startDateTime;
    }

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
