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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'assignedMemberId': assignedMemberId,
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String?,
      title: map['title'] ?? '',
      description: map['description'] as String?,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      assignedMemberId: map['assignedMemberId'] as String?,
    );
  }
}

