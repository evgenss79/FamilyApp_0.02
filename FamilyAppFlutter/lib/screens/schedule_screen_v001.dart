import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data_v001.dart';

class ScheduleScreenV001 extends StatelessWidget {
  const ScheduleScreenV001({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        final List<_ScheduleItem> items = [];
        for (final task in data.tasks) {
          if (task.dueDate != null) {
            items.add(_ScheduleItem(
              date: task.dueDate!,
              title: task.title,
              description: task.description,
              type: 'Task',
            ));
          }
        }
        for (final event in data.events) {
          items.add(_ScheduleItem(
            date: event.date,
            title: event.title,
            description: event.description,
            type: 'Event',
          ));
        }
        items.sort((a, b) => a.date.compareTo(b.date));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedule'),
          ),
          body: items.isEmpty
              ? const Center(child: Text('No tasks or events scheduled.'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final date = item.date;
                    final dateString =
                        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      leading: Icon(item.type == 'Task'
                          ? Icons.check_circle_outline
                          : Icons.event),
                      title: Text(item.title),
                      subtitle: Text(
                          '${item.description.isNotEmpty ? item.description + '\n' : ''}$dateString'),
                      isThreeLine: item.description.isNotEmpty,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ScheduleItem {
  final DateTime date;
  final String title;
  final String description;
  final String type;

  _ScheduleItem({
    required this.date,
    required this.title,
    required this.description,
    required this.type,
  });
}
