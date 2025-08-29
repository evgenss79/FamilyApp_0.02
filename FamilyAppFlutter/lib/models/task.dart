import 'package:uuid/uuid.dart';

/// Model representing a task that can be assigned to one or more family members.
///
/// This version extends the original `Task` model by including a
/// status string (e.g. 'pending', 'inProgress', 'done'), a points
/// counter and an optional reminder date. These fields allow tasks
/// to track completion state, reward points for completing chores
/// and set reminders independent of the due date.
class Task {
  /// Unique identifier for the task.
  final String id;

  /// Title summarizing the task.
  final String title;

  /// Optional description providing more detail.
  final String? description;

  /// Optional due date and time when the task should be completed.
  final DateTime? dueDate;

  /// Identifier of the member assigned to the task, if any.
  /// This field is mutable so that tasks can be unassigned when a member is removed.
  String? assignedMemberId;

  /// Status of the task ('pending' by default).
  String status;

  /// Points awarded upon completion of the task.
  int points;

  /// Optional reminder date independent of the due date.
  DateTime? reminderDate;

  Task({
    String? id,
    required this.title,
    this.description,
    this.dueDate,
    this.assignedMemberId,
    this.status = 'pending',
    this.points = 0,
    this.reminderDate,
  }) : id = id ?? const Uuid().v4();

  /// Convert this task to a map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'assignedMemberId': assignedMemberId,
      'status': status,
      'points': points,
      'reminderDate': reminderDate?.toIso8601String(),
    };
  }

  /// Construct a task from a persisted map.
  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      assignedMemberId: map['assignedMemberId'],
      status: map['status'] ?? 'pending',
      points: map['points'] ?? 0,
      reminderDate: map['reminderDate'] != null ? DateTime.parse(map['reminderDate'] as String) : null,
    );
  }
}