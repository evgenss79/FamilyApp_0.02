import 'package:uuid/uuid.dart';

/// Model representing a task that can be assigned to one or more family members.
///
/// This version extends the original 'Task' model by including:
/// - status string (e.g. 'pending', 'inProgress', 'done', 'overdue')
/// - reward points for completing the task
/// - start and end date/time for scheduling
/// - a list of reminder times
/// - an optional assigned member
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
  int points;

  /// Optional list of reminder times independent of the end date.
  final List<DateTime> reminders;

  Task({
    String? id,
    required this.title,
    this.description,
    this.startDateTime,
    this.endDateTime,
        DateTime? dueDate,

    this.assignedMemberId,
    this.status = 'pending',

        this.points = 0,

    List<DateTime>? reminders,
  })  : id = id ?? const Uuid().v4(),
        reminders = reminders ?? [];

  /// Convert this task to a map for persistence.
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
    };
  }

  /// Construct a task from a persisted map.
  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      startDateTime: map['startDateTime'] != null
          ? DateTime.parse(map['startDateTime'] as String)
          : null,
      endDateTime:
          map['endDateTime'] != null ? DateTime.parse(map['endDateTime'] as String) : null,
      assignedMemberId: map['assignedMemberId'] as String?,
      status: map['status'] as String? ?? 'pending',
      points: map['points'] as int? ?? 0,
      reminders: (map['reminders'] as List?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
    );
  }
}
