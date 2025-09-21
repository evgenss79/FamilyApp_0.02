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

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      status: _statusFromString(map['status'] as String?),
      assigneeId: map['assigneeId'] as String?,
      points: map['points'] as int?,
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
