import 'package:uuid/uuid.dart';

/// Model representing a task that can be assigned to one or more family members.
///
/// This version extends the original 'Task' model by including:
/// - status string (e.g. 'pending', 'inProgress', 'done', 'overdue')
/// - reward points for completing the task
/// - start and end date/time for scheduling
/// - a list of reminder times
/// - an optional assigned member
/// - updatedAt timestamp for conflict resolution during sync
class Task {
  /// Unique identifier for the task.
  final String id;

  /// Title summarizing the task.
  final String title;

  /// Optional description providing more detail.
  final String? description;

  /// Optional start date and time when the task begins.
  final DateTime? startDateTime;

  /// Optional end date and time when the task should be completed.
  final DateTime? endDateTime;

  /// Optional alias for backward compatibility. Returns the due date (same as endDateTime).
  DateTime? get dueDate => endDateTime;

  /// Identifier of the member assigned to the task, if any.
  /// This field is mutable so that tasks can be unassigned when a member is removed.
  String? assignedMemberId;

  /// Status of the task ('pending' by default).
  String status;

  /// Points awarded upon completion of the task.
  late int points;

  /// Optional latitude coordinate for location-based reminders.
  final double? latitude;

  /// Optional longitude coordinate for location-based reminders.
  final double? longitude;

  /// Optional human-readable location name for display.
  final String? locationName;

  /// Optional list of reminder times independent of the end date.
  final List<DateTime> reminders;

  /// Timestamp of last update for conflict resolution.
  final DateTime updatedAt;

  Task({
    String? id,
    required this.title,
    this.description,
    this.startDateTime,
    this.endDateTime,
    DateTime? dueDate, // legacy parameter retained for compatibility; ignored
    this.assignedMemberId,
    this.status = 'pending',
    int? points,
    List<DateTime>? reminders,
    DateTime? updatedAt,
    this.latitude,
    this.longitude,
    this.locationName,
  })  : id = id ?? const Uuid().v4(),
        points = points ?? 0,
        reminders = reminders ?? const [],
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'assignedMemberId': assignedMemberId,
      'status': status,
      'points': points,
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    DateTime? _parseDateTime(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    }

    // reminders может быть List<String> или уже List<dynamic>
    final remindersList = (map['reminders'] as List?)
            ?.map((e) => DateTime.parse(e as String))
            .toList() ??
        <DateTime>[];

    final rawUpdated = map['updatedAt'];
    final parsedUpdated = _parseDateTime(rawUpdated) ?? DateTime.now();

    return Task(
      id: map['id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      startDateTime: _parseDateTime(map['startDateTime']),
      endDateTime: _parseDateTime(map['endDateTime']),
      assignedMemberId: map['assignedMemberId'] as String?,
      status: (map['status'] as String?) ?? 'pending',
      points: (map['points'] as int?) ?? 0,
      reminders: remindersList,
      updatedAt: parsedUpdated,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['locationName'] as String?,
    );
  }
}
