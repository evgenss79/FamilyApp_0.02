import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
      appBar: AppBar(title: Text(context.tr('tasks'))),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final tasks = data.tasks;
          if (data.isLoading && tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tasks.isEmpty) {
            return Center(child: Text(context.tr('noTasksLabel')));
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
                        label: Text(context.tr('taskStatus.${task.status.name}')),
                        backgroundColor:

                            _statusColor(context, task.status)
                                .withValues(alpha: 0.12),

                      ),
                      if (task.description?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(task.description!),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${context.tr('taskDueDate')}: ${_formatDueDate(task.dueDate, context)}',
                        ),
                      ),
                      Text(
                        '${context.tr('assignToLabel')}: ${assigneeName?.isNotEmpty == true ? assigneeName : context.tr('unassignedLabel')}',
                      ),
                      if (task.points != null)
                        Text('${context.tr('rewardPointsLabel')}: ${task.points}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'todo':
                          await context
                              .read<FamilyData>()
                              .updateTaskStatus(task.id, TaskStatus.todo);
                          break;
                        case 'inProgress':
                          await context
                              .read<FamilyData>()
                              .updateTaskStatus(task.id, TaskStatus.inProgress);
                          break;
                        case 'done':
                          await context
                              .read<FamilyData>()
                              .updateTaskStatus(task.id, TaskStatus.done);
                          break;
                        case 'delete':
                          _confirmDelete(context, task);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'todo',
                        child: ListTile(
                          leading: const Icon(Icons.radio_button_unchecked),
                          title: Text(context.tr('markTodoAction')),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'inProgress',
                        child: ListTile(
                          leading: const Icon(Icons.timelapse),
                          title: Text(context.tr('markInProgressAction')),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'done',
                        child: ListTile(
                          leading: const Icon(Icons.check_circle),
                          title: Text(context.tr('markDoneAction')),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: const Icon(Icons.delete),
                          title: Text(context.tr('deleteTaskAction')),
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
        tooltip: context.tr('addTaskTitle'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDueDate(DateTime? date, BuildContext context) {
    if (date == null) return context.tr('noDueDate');
    return context.loc.formatDate(date, withTime: true);
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
        title: Text(context.tr('deleteTaskAction')),
        content: Text(context.loc.confirmDelete(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancelAction')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<FamilyData>().removeTask(task.id);
              if (context.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Text(context.tr('deleteAction')),
          ),
        ],
      ),
    );
  }
}
