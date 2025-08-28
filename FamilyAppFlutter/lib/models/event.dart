import 'package:uuid/uuid.dart';

/// Model representing a family event or appointment.
class Event {
  /// Unique identifier for the event.
  final String id;

  /// Title summarizing the event.
  final String title;

  /// Date and time of the event.
  final DateTime date;

  /// Optional description or details about the event.
  final String? description;

  Event({
    String? id,
    required this.title,
    required this.date,
    this.description,
  }) : id = id ?? const Uuid().v4();
}
