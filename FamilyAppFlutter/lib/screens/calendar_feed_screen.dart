import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../providers/schedule_data.dart';
import '../models/schedule_item.dart';

/// A unified feed screen combining tasks, events and schedule items.
/// Items are sorted chronologically and display title,
/// optional description or time range.
class CalendarFeedScreenV001 extends StatelessWidget {
  const CalendarFeedScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FamilyDataV001, ScheduleDataV001>(
      builder: (context, data, scheduleData, child) {
        // Build feed items list from tasks, events and schedule items
        final List<_FeedItem> items = [];
        // Tasks
        for (final task in data.tasks) {
          if (task.endDateTime != null) {
            final date = task.endDateTime!;
            final parts = <String>[];
            if (task.description != null && task.description!.isNotEmpty) {
              parts.add(task.description!);
            }
            final d = date;
            final dateTimeString =
                '${d.day.toString().padLeft(2, '0')}.'
                '${d.month.toString().padLeft(2, '0')}.'
                '${d.year} '
                '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
            parts.add(dateTimeString);
            items.add(_FeedItem(
              title: task.title,
              subtitle: parts.join('\n'),
              date: date,
              type: 'task',
            ));
          }
        }
        // Events
        for (final event in data.events) {
          final start = event.startDateTime;
          final end = event.endDateTime;
          final startString =
              '${start.day.toString().padLeft(2, '0')}.'
              '${start.month.toString().padLeft(2, '0')}.'
              '${start.year} '
              '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
          final endString =
              '${end.day.toString().padLeft(2, '0')}.'
              '${end.month.toString().padLeft(2, '0')}.'
              '${end.year} '
              '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
          final rangeString =
              start.isAtSameMomentAs(end)
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
            type: 'event',
          ));
        }
        // Schedule items
        for (final item in scheduleData.items) {
          final start = item.startDateTime;
          final end = item.endDateTime;
          final parts = <String>[];
          if (item.description != null && item.description!.isNotEmpty) {
            parts.add(item.description!);
          }
          if (end != null) {
            final startString =
                '${start.day.toString().padLeft(2, '0')}.'
                '${start.month.toString().padLeft(2, '0')}.'
                '${start.year} '
                '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
            final endString =
                '${end.day.toString().padLeft(2, '0')}.'
                '${end.month.toString().padLeft(2, '0')}.'
                '${end.year} '
                '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
            final rangeString =
                start.isAtSameMomentAs(end)
                    ? startString
                    : '$startString - $endString';
            parts.add(rangeString);
          } else {
            final d = start;
            final dateTimeString =
                '${d.day.toString().padLeft(2, '0')}.'
                '${d.month.toString().padLeft(2, '0')}.'
                '${d.year} '
                '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
            parts.add(dateTimeString);
          }
          items.add(_FeedItem(
            title: item.title,
            subtitle: parts.join('\n'),
            date: start,
            type: 'schedule',
          ));
        }
        // sort by date/time
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
                    IconData icon;
                    switch (item.type) {
                      case 'task':
                        icon = Icons.check_box;
                        break;
                      case 'event':
                        icon = Icons.event;
                        break;
                      case 'schedule':
                      default:
                        icon = Icons.schedule;
                        break;
                    }
                    return ListTile(
                      leading: Icon(icon),
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
  /// The type of feed item: 'task', 'event', or 'schedule'.
  final String type;

  _FeedItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
  });
}
