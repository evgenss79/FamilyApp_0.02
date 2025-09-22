import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/family_data.dart';
import 'add_task_screen.dart';

/// Displays a list of tasks and allows adding new tasks.  Each task
/// shows its title, status, due date, assigned member and points.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final tasks = data.tasks;
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks added yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final assigneeName = task.assigneeId == null
                  ? null
                  : data.memberById(task.assigneeId!)?.name;
              return Card(
                child: ListTile(
                  leading: Icon(
                    _statusIcon(task.status),
                    color: _statusColor(context, task.status),
                  ),
                  title: Text(task.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(task.status.name),
                        backgroundColor:
                            _statusColor(context, task.status).withValues(alpha: 0.12),
                      ),
                      if (task.description?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(task.description!),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Due: ${_formatDueDate(task.dueDate)}',
                        ),
                      ),
                      Text(
                        'Assignee: ${assigneeName?.isNotEmpty == true ? assigneeName : 'Unassigned'}',
                      ),
                      if (task.points != null)
                        Text('Points: ${task.points}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'todo':
                          context
                              .read<FamilyData>()
                              .updateTaskStatus(task.id, TaskStatus.todo);
                          break;
                        case 'inProgress':
                          context
                              .read<FamilyData>()
                              .updateTaskStatus(task.id, TaskStatus.inProgress);
                          break;
                        case 'done':
                          context
                              .read<FamilyData>()
                              .updateTaskStatus(task.id, TaskStatus.done);
                          break;
                        case 'delete':
                          _confirmDelete(context, task);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'todo',
                        child: ListTile(
                          leading: Icon(Icons.radio_button_unchecked),
                          title: Text('Mark as TODO'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'inProgress',
                        child: ListTile(
                          leading: Icon(Icons.timelapse),
                          title: Text('Mark in progress'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'done',
                        child: ListTile(
                          leading: Icon(Icons.check_circle),
                          title: Text('Mark as done'),
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete task'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.timelapse;
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }

  Color _statusColor(BuildContext context, TaskStatus status) {
    final colors = Theme.of(context).colorScheme;
    switch (status) {
      case TaskStatus.todo:
        return colors.primary;
      case TaskStatus.inProgress:
        return colors.tertiary;
      case TaskStatus.done:
        return colors.secondary;
    }
  }

  void _confirmDelete(BuildContext context, Task task) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FamilyData>().removeTask(task.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
