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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String?,
      title: map['title'] ?? '',
      date: DateTime.parse(map['date']),
      description: map['description'] as String?,
    );
  }
}
