import '../utils/parsing.dart';

/// Possible states of a task.
enum TaskStatus { todo, inProgress, done }

/// Model describing a family task with optional assignee and due date.
class Task {
  static const Object _sentinel = Object();

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.status = TaskStatus.todo,
    this.assigneeId,
    this.points,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskStatus status;
  final String? assigneeId;
  final int? points;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description'] as String?,
      dueDate: parseNullableDateTime(map['dueDate']),
      status: _statusFromString(map['status']) ?? TaskStatus.todo,
      assigneeId: map['assigneeId'] as String?,
      points: _parsePoints(map['points']),
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'assigneeId': assigneeId,
        'points': points,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Task copyWith({
    Object? title = _sentinel,
    Object? description = _sentinel,
    Object? dueDate = _sentinel,
    Object? status = _sentinel,
    Object? assigneeId = _sentinel,
    Object? points = _sentinel,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
  }) {
    return Task(
      id: id,
      title: title == _sentinel ? this.title : title as String,
      description:
          description == _sentinel ? this.description : description as String?,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      status:
          status == _sentinel ? this.status : status as TaskStatus,
      assigneeId:
          assigneeId == _sentinel ? this.assigneeId : assigneeId as String?,
      points: points == _sentinel ? this.points : points as int?,
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
    );
  }

  static TaskStatus? _statusFromString(dynamic value) {
    if (value is TaskStatus) {
      return value;
    }
    final String? raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final TaskStatus status in TaskStatus.values) {
      if (status.name.toLowerCase() == raw.toLowerCase()) {
        return status;
      }
    }
    return null;
  }

  static int? _parsePoints(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }
}
