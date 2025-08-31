import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/task.dart';
import '../models/event.dart';

/// A unified feed screen combining tasks and events.
/// Items are sorted chronologically and display title,
/// optional description or time range.
class CalendarFeedScreenV001 extends StatelessWidget {
  const CalendarFeedScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        // Build feed items list
        final List<_FeedItem> items = [];
        for (final task in data.tasks) {
          if (task.endDateTime != null) {
            final date = task.endDateTime!;
            final parts = <String>[];
            if (task.description != null && task.description!.isNotEmpty) {
              parts.add(task.description!);
            }
            final d = date;
            final dateTimeString = '${d.day.toString().padLeft(2, '0')}.'
                '${d.month.toString().padLeft(2, '0')}.'
                '${d.year} '
                '${d.hour.toString().padLeft(2, '0')}:'
                '${d.minute.toString().padLeft(2, '0')}';
            parts.add(dateTimeString);
            items.add(_FeedItem(
              title: task.title,
              subtitle: parts.join('\n'),
              date: date,
              isTask: true,
            ));
          }
        }
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
          final parts = <String>[];
          if (event.description != null && event.description!.isNotEmpty) {
            parts.add(event.description!);
          }
          parts.add(rangeString);
          items.add(_FeedItem(
            title: event.title,
            subtitle: parts.join('\n'),
            date: start,
            isTask: false,
          ));
        }
        items.sort((a, b) => a.date.compareTo(b.date));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Feed'),
          ),
          body: items.isEmpty
              ? const Center(child: Text('No items yet.'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading:
                          Icon(item.isTask ? Icons.check_box : Icons.event),
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                      isThreeLine: item.subtitle.contains('\n'),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _FeedItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final bool isTask;

  _FeedItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.isTask,
  });
}
