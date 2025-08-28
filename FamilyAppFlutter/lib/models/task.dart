import 'package:uuid/uuid.dart';

/// Model representing a task that can be assigned to one or more family members.
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
 String? assignedMemberId;

  Task({
    String? id,
    required this.title,
    this.description,
    this.dueDate,
    this.assignedMemberId,
  }) : id = id ?? const Uuid().v4();
}
