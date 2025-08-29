import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data_v001.dart';
import '../screens/add_task_screen.dart';
import '../models/family_member_v001.dart';

/// Screen displaying a list of tasks for version 0.01.
///
/// Each task card shows the title, optional description, due date,
/// assigned member, status, points and an optional reminder. Users can
/// delete tasks via the trailing delete icon or add new tasks using
/// the floating action button. The list automatically updates via
/// the `FamilyDataV001` provider.
class TasksScreenV001 extends StatelessWidget {
  const TasksScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
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
                    FamilyMember? assignedMember;
                    for (final member in members) {
                      if (member.id == task.assignedMemberId) {
                        assignedMember = member;
                        break;
                      }
                    }
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description?.isNotEmpty ?? false)
                            Text(task.description!),
                          if (task.dueDate != null)
                            Text('Due: ${task.dueDate}'),
                          if (assignedMember != null)
                            Text('Assigned: ${assignedMember.name}'),
                          // Show status and points for the task
                          Text('Status: ${task.status}'),
                          Text('Points: ${task.points}'),
                          if (task.reminderDate != null)
                            Text('Reminder: ${task.reminderDate}'),
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
                MaterialPageRoute(
                  builder: (context) => const AddTaskScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
