import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../screens/add_task_screen.dart';
import '../models/family_member.dart';

/// Screen displaying a list of tasks.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyData>(
      builder: (context, data, _) {
        final tasks = data.tasks;
        final members = data.members;
        return Scaffold(
          appBar: AppBar(title: const Text('Tasks')),
          body: tasks.isEmpty
              ? const Center(child: Text('No tasks created yet.'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    // Find the assigned member if any.
                    FamilyMember? assignedMember;
                    for (final member in members) {
                      if (member.id == task.assignedMemberId) {
                        assignedMember = member;
                        break;
                      }
                    }
                    return ListTile(
                      leading: const Icon(Icons.task_alt),
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description != null && task.description!.isNotEmpty)
                            Text(task.description!),
                          if (task.dueDate != null)
                            Text('Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}'),
                          if (assignedMember != null)
                            Text('Assigned to: ${assignedMember.name}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          data.removeTask(task);
                        },
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
