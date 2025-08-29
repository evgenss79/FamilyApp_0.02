import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data_v001.dart';

/// A unified schedule screen combining tasks and events for version 0.01.
///
/// Tasks with a due date and all events are collated into a single list,
/// sorted chronologically. Each item indicates whether it originates
/// from a task or an event and displays its title, an optional
/// description and the date/time. Handling of nullable descriptions
/// avoids type errors when constructing `Text` widgets.
class ScheduleScreenV001 extends StatelessWidget {
  const ScheduleScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        final List<_ScheduleItem> items = [];
        for (final task in data.tasks) {
          if (task.dueDate != null) {
            items.add(_ScheduleItem(
              title: task.title,
              description: task.description ?? '',
              date: task.dueDate!,
              type: 'Task',
            ));
          }
        }
        for (final event in data.events) {
          items.add(_ScheduleItem(
            title: event.title,
            description: event.description ?? '',
            date: event.date,
            type: 'Event',
          ));
        }
        items.sort((a, b) => a.date.compareTo(b.date));
        return Scaffold(
          appBar: AppBar(title: const Text('Schedule')),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(
                    item.type == 'Task' ? Icons.checklist : Icons.event),
                title: Text(item.title),
                subtitle: item.description.isNotEmpty
                    ? Text('${item.description}\n${item.date}')
                    : Text('${item.date}'),
              );
            },
          ),
        );
      },
    );
  }
}

/// Internal data structure representing a schedule entry.
class _ScheduleItem {
  final String title;
  final String description;
  final DateTime date;
  final String type;

  _ScheduleItem({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}