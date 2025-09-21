import 'package:hive/hive.dart';

/// Represents a task within the family application.  Tasks can be
/// assigned to a family member and may carry a point value that
/// contributes to the scoreboard when completed.  This model does not
/// enforce any particular business logic; it simply holds data.
@HiveType(typeId: 31)
enum TaskStatus {
  /// The task has been created but not yet started.
  @HiveField(0)
  pending,

  /// Work is actively in progress on the task.
  @HiveField(1)
  inProgress,

  /// The task has been completed.
  @HiveField(2)
  completed,
}

@HiveType(typeId: 32)
class Task extends HiveObject {
  /// Unique identifier for this task.
  @HiveField(0)
  String? id;

  /// A short title describing the task.
  @HiveField(1)
  String? title;

  /// A more detailed description of the task.
  @HiveField(2)
  String? description;

  /// Identifier of the family member this task is assigned to, if any.
  @HiveField(3)
  String? assignedMemberId;

  /// When the task is due, if applicable.
  @HiveField(4)
  DateTime? dueDate;

  /// The current status of the task.
  @HiveField(5)
  TaskStatus? status;

  /// Point value awarded upon completion of the task.
  @HiveField(6)
  int? points;

  Task({
    this.id,
    this.title,
    this.description,
    this.assignedMemberId,
    this.dueDate,
    this.status,
    this.points,
  });
}