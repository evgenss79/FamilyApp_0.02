import 'package:uuid/uuid.dart';

/// Model representing a family event or appointment.
class Event {
  /// Unique identifier for the event.
  final String id;

  /// Title summarizing the event.
  final String title;

  /// Start date and time of the event.
  ///
  /// In earlier versions of the app only a single `date` field was stored.  To
  /// maintain backwards compatibility, this field will be populated from
  /// `date` if `startDateTime` is not present in persisted data.
  final DateTime startDateTime;

  /// End date and time of the event.  If no distinct end time is provided the
  /// end time will match the start time.
  final DateTime endDateTime;

  /// Optional description or details about the event.
  final String? description;

  /// Construct a new [Event].  Both [startDateTime] and [endDateTime] must be
  /// provided; if they are equal the event represents a single moment in
  /// time.  The [id] will be automatically generated if omitted.
  Event({
    String? id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
  }) : id = id ?? const Uuid().v4();

  /// Backwards-compatible getter for code that still expects a `date` field.
  /// Returns the [startDateTime] value.
  DateTime get date => startDateTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      // Persist both start and end times.  Converting to ISO 8601 strings
      // preserves full date and time resolution.
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'description': description,
    };
  }

  /// Construct an [Event] from persisted data.  If only `date` is present
  /// (from older app versions) it will populate both [startDateTime] and
  /// [endDateTime] with that value.  Otherwise the new keys are used.
  static Event fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final title = map['title'] ?? '';
    // Attempt to read new fields first.
    final startString = map['startDateTime'] as String?;
    final endString = map['endDateTime'] as String?;
    DateTime start;
    DateTime end;
    if (startString != null && endString != null) {
      start = DateTime.parse(startString);
      end = DateTime.parse(endString);
    } else {
      // Fallback for older data where only `date` was stored.
      final dateString = map['date'] as String?;
      final parsed = dateString != null ? DateTime.parse(dateString) : DateTime.now();
      start = parsed;
      end = parsed;
    }
    final description = map['description'] as String?;
    return Event(
      id: id,
      title: title,
      startDateTime: start,
      endDateTime: end,
      description: description,
    );
  }
}
