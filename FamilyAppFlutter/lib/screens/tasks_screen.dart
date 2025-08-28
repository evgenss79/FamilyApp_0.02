import 'package:flutter/material.dart';
import '../models/task.dart';

/// Screen displaying a list of tasks.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder list of tasks. Later this will come from a data store or backend.
    final List<Task> tasks = [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks created yet.'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(task.title),
                  subtitle: task.description != null && task.description!.isNotEmpty
                      ? Text(task.description!)
                      : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to add task screen / show dialog.
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
