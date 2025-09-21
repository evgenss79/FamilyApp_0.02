import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../providers/schedule_data.dart';
import '../models/schedule_item.dart';

/// A screen that displays a calendar view combining tasks, events and schedule items.
/// Selecting a date displays a list of tasks, events and schedule items for that day.
class CalendarScreenV001 extends StatefulWidget {
  const CalendarScreenV001({super.key});

  @override
  State<CalendarScreenV001> createState() => _CalendarScreenV001State();
}

class _CalendarScreenV001State extends State<CalendarScreenV001> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  /// Builds a map where the key is the date (year-month-day) and
  /// the value is a list of tasks, events and schedule items occurring on that date.
  Map<DateTime, List<dynamic>> _buildEvents(FamilyDataV001 data, ScheduleDataV001 scheduleData) {
    final Map<DateTime, List<dynamic>> events = {};
    // tasks
    for (final task in data.tasks) {
      if (task.endDateTime != null) {
        final date = DateTime(task.endDateTime!.year, task.endDateTime!.month, task.endDateTime!.day);
        events[date] = (events[date] ?? [])..add(task);
      }
    }
    // events
    for (final event in data.events) {
      final date = DateTime(event.startDateTime.year, event.startDateTime.month, event.startDateTime.day);
      events[date] = (events[date] ?? [])..add(event);
    }
    // schedule items
    for (final item in scheduleData.items) {
      final date = DateTime(item.startDateTime.year, item.startDateTime.month, item.startDateTime.day);
      events[date] = (events[date] ?? [])..add(item);
    }
    return events;
  }

  /// Returns the list of items for the given day.
  List<dynamic> _getEventsForDay(DateTime day, Map<DateTime, List<dynamic>> events) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<FamilyDataV001>(context);
    final scheduleData = Provider.of<ScheduleDataV001>(context);
    final eventsMap = _buildEvents(data, scheduleData);
    final selectedItems = _getEventsForDay(_selectedDay, eventsMap);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            eventLoader: (day) => _getEventsForDay(day, eventsMap),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final item = selectedItems[index];
                if (item is Task) {
                  final parts = <String>[];
                  if (item.description != null && item.description!.isNotEmpty) {
                    parts.add(item.description!);
                  }
                  final d = item.endDateTime;
                    if (d != null) {
                    final dateTimeString =
                        '${d.day.toString().padLeft(2, '0')}.'
                        '${d.month.toString().padLeft(2, '0')}.'
                        '${d.year} '
                        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                    parts.add(dateTimeString);
                  }
                  return ListTile(
                    leading: const Icon(Icons.check_box),
                    title: Text(item.title),
                    subtitle: Text(parts.join('\n')),
                    isThreeLine: parts.join('\n').contains('\n'),
                  );
                } else if (item is Event) {
                  final start = item.startDateTime;
                  final end = item.endDateTime;
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
                  if (item.description != null && item.description!.isNotEmpty) {
                    parts.add(item.description!);
                  }
                  parts.add(rangeString);
                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(item.title),
                    subtitle: Text(parts.join('\n')),
                    isThreeLine: parts.join('\n').contains('\n'),
                  );
                } else if (item is ScheduleItem) {
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
                  return ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(item.title),
                    subtitle: Text(parts.join('\n')),
                    isThreeLine: parts.join('\n').contains('\n'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
