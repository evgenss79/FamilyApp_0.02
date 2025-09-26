import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/task.dart';
import '../providers/family_data.dart';
import 'add_task_screen.dart';

/// Displays a list of tasks and allows adding new tasks.  Each task
/// shows its title, status, due date, assigned member and points.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  static const String routeName = 'TasksScreen';

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('tasks'))),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final List<Task> filtered = _applyFilter(data.tasks);
          if (data.isLoading && data.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (filtered.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterBar(context),
                ),
                const SizedBox(height: 24),
                Text(context.tr('noTasksLabel')),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _buildFilterBar(context),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final Task task = filtered[index];
                    final String? assigneeName = task.assigneeId == null
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
                              label: Text(
                                  context.tr('taskStatus.${task.status.name}')),
                              backgroundColor: _statusColor(context, task.status)
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
                              Text(
                                  '${context.tr('rewardPointsLabel')}: ${task.points}'),
                            if (task.locationLabel != null ||
                                (task.latitude != null &&
                                    task.longitude != null))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.place, size: 18),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        task.locationLabel ??
                                            '${task.latitude!.toStringAsFixed(4)}, ${task.longitude!.toStringAsFixed(4)}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (task.reminderEnabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.alarm, size: 18),
                                    const SizedBox(width: 4),
                                    Text(context.tr('taskReminderActiveLabel')),
                                  ],
                                ),
                              ),
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
                                    .updateTaskStatus(
                                        task.id, TaskStatus.inProgress);
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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddTaskScreen(),
              settings: const RouteSettings(
                name: AddTaskScreen.routeName,
              ),
            ),
          );
        },
        tooltip: context.tr('addTaskTitle'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _TaskFilter.values.map((filter) {
        final bool selected = _filter == filter;
        return ChoiceChip(
          label: Text(context.tr(_filterLabel(filter))),
          selected: selected,
          onSelected: (_) => setState(() => _filter = filter),
        );
      }).toList(),
    );
  }

  List<Task> _applyFilter(List<Task> tasks) {
    switch (_filter) {
      case _TaskFilter.todo:
        return tasks.where((task) => task.status == TaskStatus.todo).toList();
      case _TaskFilter.inProgress:
        return tasks
            .where((task) => task.status == TaskStatus.inProgress)
            .toList();
      case _TaskFilter.done:
        return tasks.where((task) => task.status == TaskStatus.done).toList();
      case _TaskFilter.all:
        return tasks;
    }
  }

  String _filterLabel(_TaskFilter filter) {
    switch (filter) {
      case _TaskFilter.all:
        return 'taskFilterAll';
      case _TaskFilter.todo:
        return 'taskFilterTodo';
      case _TaskFilter.inProgress:
        return 'taskFilterInProgress';
      case _TaskFilter.done:
        return 'taskFilterDone';
    }
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
    final ColorScheme colors = Theme.of(context).colorScheme;
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

enum _TaskFilter { all, todo, inProgress, done }
