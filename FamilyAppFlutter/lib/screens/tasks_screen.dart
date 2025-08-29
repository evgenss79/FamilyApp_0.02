import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../screens/add_task_screen.dart';
import '../models/family_member.dart';
import '../models/task.dart';

/// Displays a list of tasks with the ability to update their status, view
/// additional metadata and delete tasks.  Users can also create new tasks
/// via the floating action button.
class TasksScreenV001 extends StatelessWidget {
  const TasksScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        final tasks = data.tasks;
        return Scaffold(
          appBar: AppBar(title: const Text('Tasks')),
          body: tasks.isEmpty
              ? const Center(child: Text('No tasks created yet.'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    FamilyMember? member;
                    for (final m in data.members) {
                      if (m.id == task.assignedMemberId) {
                        member = m;
                        break;
                      }
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description != null && task.description!.isNotEmpty)
                              Text(task.description!),
                            if (task.dueDate != null)
                              Text(
                                  'Due: '
                                  '${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}'
                                  '-${task.dueDate!.day.toString().padLeft(2, '0')}'),
                            Text('Status: ${task.status}'),
                            Text('Points: ${task.points}'),
                            if (task.reminderDate != null)
                              Text(
                                  'Reminder: '
                                  '${task.reminderDate!.year}-${task.reminderDate!.month.toString().padLeft(2, '0')}'
                                  '-${task.reminderDate!.day.toString().padLeft(2, '0')}'),
                            if (member != null) Text('Assigned to: ${member.name}'),
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
                                  dueDate: task.dueDate,
                                  assignedMemberId: task.assignedMemberId,
                                  status: value,
                                  points: task.points,
                                  reminderDate: task.reminderDate,
                                );
                                data.updateTask(updatedTask);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'Pending', child: Text('Mark as Pending')),
                                PopupMenuItem(value: 'In Progress', child: Text('Mark as In Progress')),
                                PopupMenuItem(value: 'Completed', child: Text('Mark as Completed')),
                              ],
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => data.removeTask(task),
                            ),
                          ],
                        ),
                      ),
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
      },
    );
  }
}