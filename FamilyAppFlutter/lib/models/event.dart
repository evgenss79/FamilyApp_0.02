import 'package:hive/hive.dart';

/// Represents a calendar event.  Events can be associated with a
/// particular family member, have a start and end time, and optionally
/// include a description or location.  All fields are optional except
/// the identifier, allowing for flexible creation of events.
@HiveType(typeId: 33)
class Event extends HiveObject {
  /// Unique identifier for this event.
  @HiveField(0)
  String? id;

  /// Title or summary for the event.
  @HiveField(1)
  String? title;

  /// Detailed description of the event.
  @HiveField(2)
  String? description;

  /// Start date and time of the event.
  @HiveField(3)
  DateTime? startDateTime;

  /// End date and time of the event.
  @HiveField(4)
  DateTime? endDateTime;

  /// Physical or virtual location of the event.
  @HiveField(5)
  String? location;

  /// Identifier of the family member associated with this event, if any.
  @HiveField(6)
  String? assignedMemberId;

  Event({
    this.id,
    this.title,
    this.description,
    this.startDateTime,
    this.endDateTime,
    this.location,
    this.assignedMemberId,
  });
}