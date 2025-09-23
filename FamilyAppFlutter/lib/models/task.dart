import 'package:family_app_flutter/utils/parsing.dart';

enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  String title;
  String? description;
  DateTime? dueDate;
  TaskStatus status;
  String? assigneeId; // id участника семьи
  int? points; // баллы для поощрений/штрафов

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.status = TaskStatus.todo,
    this.assigneeId,
    this.points,
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

  Map<String, dynamic> toEncodableMap() => <String, dynamic>{
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'assigneeId': assigneeId,
        'points': points,
      };

  Map<String, dynamic> toLocalMap() => <String, dynamic>{
        'id': id,
        ...toEncodableMap(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static Task fromDecodableMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: parseNullableDateTime(map['dueDate']),
      status: TaskStatus.values.firstWhere(
        (TaskStatus status) => status.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      assigneeId: map['assigneeId'] as String?,
      points: map['points'] is int
          ? map['points'] as int
          : int.tryParse('${map['points']}'),
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'status': status.name,
      'assigneeId': assigneeId,
      'points': points,
    };
  }

  static TaskStatus _statusFromString(String? s) {
    switch (s) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}
