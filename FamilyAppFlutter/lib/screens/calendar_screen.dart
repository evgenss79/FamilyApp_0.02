import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../models/task.dart';
import '../providers/family_data.dart';

/// Displays a simple aggregated view of upcoming events and tasks with
/// friendly formatting.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final events = data.events.toList()
            ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
          final tasks = data.tasks.toList()
            ..sort((a, b) => (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

          if (events.isEmpty && tasks.isEmpty) {
            return const Center(child: Text('No events or tasks'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (events.isNotEmpty) ...[
                Text(
                  'Upcoming events',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final Event event in events)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(event.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatRange(event.startDateTime, event.endDateTime)),
                          if (event.description?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(event.description!),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (tasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final Task task in tasks)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: _statusColor(context, task.status),
                      ),
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${task.status.name}'),
                          Text('Due: ${_formatDate(task.dueDate)}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');
    return '${formatter.format(start)} – ${formatter.format(end)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No due date';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
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
}
