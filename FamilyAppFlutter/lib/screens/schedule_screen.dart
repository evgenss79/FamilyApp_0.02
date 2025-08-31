import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';

/// A unified schedule screen combining tasks and events for version 0.01.
///
/// Tasks with a due date and all events are collated into a single list,
/// sorted chronologically. Each item indicates whether it originates
/// from a task or an event and displays its title, an optional
/// description and the date/time. Handling of nullable descriptions
/// avoids type errors when constructing `Text` widgets.
class ScheduleScreenV001 extends StatefulWidget {
  const ScheduleScreenV001({super.key});

  @override
  State<ScheduleScreenV001> createState() => _ScheduleScreenV001State();
}

class _ScheduleScreenV001State extends State<ScheduleScreenV001> {
  String _filter = 'All';

  final List<String> _filters = ['All', 'Task', 'Event'];

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        final List<_ScheduleItem> items = [];
        // Add tasks with due dates
        for (final task in data.tasks) {
          if (task.endDateTime != null) {
            items.add(_ScheduleItem(
              title: task.title,
              description: task.description ?? '',
              date: task.endDateTime!,
              type: 'Task',
            ));
          }
        }
        // Add all events. Use startDateTime as the primary date and include
        // the time range in the description field.
        for (final event in data.events) {
          final start = event.startDateTime;
          final end = event.endDateTime;
          final startString = '${start.day.toString().padLeft(2, '0')}.'
              '${start.month.toString().padLeft(2, '0')}.'
              '${start.year} '
              '${start.hour.toString().padLeft(2, '0')}:'
              '${start.minute.toString().padLeft(2, '0')}';
          final endString = '${end.day.toString().padLeft(2, '0')}.'
              '${end.month.toString().padLeft(2, '0')}.'
              '${end.year} '
              '${end.hour.toString().padLeft(2, '0')}:'
              '${end.minute.toString().padLeft(2, '0')}';
          final rangeString = start.isAtSameMomentAs(end)
              ? startString
              : '$startString - $endString';
          final desc = event.description != null && event.description!.isNotEmpty
              ? '${event.description!}\n$rangeString'
              : rangeString;
          items.add(_ScheduleItem(
            title: event.title,
            description: desc,
            date: start,
            type: 'Event',
          ));
        }
        // Sort items by date
        items.sort((a, b) => a.date.compareTo(b.date));
        // Filter items based on the selected filter
        final filteredItems = items.where((item) {
          if (_filter == 'All') return true;
          return item.type == _filter;
        }).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Schedule')),
          body: Column(
            children: [
              // Dropdown for selecting filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButton<String>(
                  value: _filter,
                  items: _filters
                      .map((f) => DropdownMenuItem<String>(
                          value: f, child: Text(f)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _filter = value;
                      });
                    }
                  },
                ),
              ),
              // List of schedule items
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return ListTile(
                      leading: Icon(item.type == 'Task'
                          ? Icons.checklist
                          : Icons.event),
                      title: Text(item.title),
                      subtitle: () {
                        if (item.type == 'Task') {
                          final parts = <String>[];
                          if (item.description.isNotEmpty) parts.add(item.description);
                          // Format date and time for tasks
                          final d = item.date;
                          final dateTimeString = '${d.day.toString().padLeft(2, '0')}.'
                              '${d.month.toString().padLeft(2, '0')}.'
                              '${d.year} '
                              '${d.hour.toString().padLeft(2, '0')}:'
                              '${d.minute.toString().padLeft(2, '0')}';
                          parts.add(dateTimeString);
                          return Text(parts.join('\n'));
                        } else {
                          // For events the description already includes the time range
                          return Text(item.description);
                        }
                      }(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Private class representing a unified schedule item.
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
