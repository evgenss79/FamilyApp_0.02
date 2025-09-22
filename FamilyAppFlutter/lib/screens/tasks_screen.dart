import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/task.dart';
import 'add_task_screen.dart';

/// Displays a list of tasks and allows adding new tasks.  Each task
/// shows its title, status and assigned member if applicable.
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
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final Task task = tasks[index];
              return ListTile(
                leading: const Icon(Icons.check_box_outline_blank),
                title: Text(task.title),
                subtitle: Text(task.status.name),
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
}