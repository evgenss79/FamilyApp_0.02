import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../screens/add_task_screen.dart';
import '../models/family_member.dart';
import '../models/task.dart';

/// Displays a list of tasks with the ability to update their status, view
/// additional metadata and delete tasks. Users can also create new tasks
/// via the floating action button.
class TasksScreenV001 extends StatefulWidget {
  const TasksScreenV001({super.key});

  @override
  State<TasksScreenV001> createState() => _TasksScreenV001State();
}

class _TasksScreenV001State extends State<TasksScreenV001> {
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        final tasks = data.tasks;
        final filteredTasks = _selectedStatus == 'All'
            ? tasks
            : tasks
                .where((t) =>
                    t.status.toLowerCase() ==
                    _selectedStatus.toLowerCase())
                .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Tasks')),
          body: filteredTasks.isEmpty
              ? const Center(child: Text('No tasks created yet.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(
                              value: 'All', child: Text('All')),
                          DropdownMenuItem(
                              value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(
                              value: 'In Progress',
                              child: Text('In Progress')),
                          DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          FamilyMember? member;
                          for (final m in data.members) {
                            if (m.id == task.assignedMemberId) {
                              member = m;
                              break;
                            }
                          }

                          final bool isOverdue =
                              task.endDateTime != null &&
                              task.endDateTime!
                                  .isBefore(DateTime.now()) &&
                              task.status.toLowerCase() != 'completed';

                          final TextStyle? overdueStyle = isOverdue
                              ? const TextStyle(color: Colors.red)
                              : null;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: ListTile(
                              title: Text(
                                task.title,
                                style: overdueStyle,
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (task.description != null &&
                                      task.description!.isNotEmpty)
                                    Text(
                                      task.description!,
                                      style: overdueStyle,
                                    ),
                                  if (task.endDateTime != null)
                                    Text(
                                      'Due: '
                                      '${task.endDateTime!.day.toString().padLeft(2, '0')}.'
                                      '${task.endDateTime!.month.toString().padLeft(2, '0')}.'
                                      '${task.endDateTime!.year} '
                                      '${task.endDateTime!.hour.toString().padLeft(2, '0')}:'
                                      '${task.endDateTime!.minute.toString().padLeft(2, '0')}',
                                      style: overdueStyle,
                                    ),
                                  Text(
                                    'Status: ${task.status}',
                                    style: overdueStyle,
                                  ),
                                  Text(
                                    'Points: ${task.points}',
                                    style: overdueStyle,
                                  ),
                                  if (member != null)
                                    Text(
                                      'Assigned to: ${member.name}',
                                      style: overdueStyle,
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      final updatedTask = Task(
                                        id: task.id,
                                        title: task.title,
                                        description: task.description,
                                        endDateTime: task.endDateTime,
                                        assignedMemberId:
                                            task.assignedMemberId,
                                        status: value,
                                        points: task.points,
                                        reminders: task.reminders,
                                      );
                                      data.updateTask(updatedTask);
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                          value: 'Pending',
                                          child:
                                              Text('Mark as Pending')),
                                      PopupMenuItem(
                                          value: 'In Progress',
                                          child: Text(
                                              'Mark as In Progress')),
                                      PopupMenuItem(
                                          value: 'Completed',
                                          child: Text(
                                              'Mark as Completed')),
                                    ],
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        data.removeTask(task),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AddTaskScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
