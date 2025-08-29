import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/task.dart';
import '../models/event.dart';

/// A screen that displays a calendar view combining tasks and events.
/// Tasks are shown on their due dates and events on their event dates.
/// Selecting a date displays a list of tasks and events for that day.
class CalendarScreenV001 extends StatefulWidget {
  const CalendarScreenV001({super.key});

  @override
  State<CalendarScreenV001> createState() => _CalendarScreenV001State();
}

class _CalendarScreenV001State extends State<CalendarScreenV001> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  /// Builds a map of events where the key is the date (year-month-day) and
  /// the value is a list of tasks and events occurring on that date.
  Map<DateTime, List<dynamic>> _buildEvents(FamilyDataV001 data) {
    final Map<DateTime, List<dynamic>> events = {};
    for (final task in data.tasks) {
      final date = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      events[date] = (events[date] ?? [])..add(task);
    }
    for (final event in data.events) {
      final date = DateTime(event.date.year, event.date.month, event.date.day);
      events[date] = (events[date] ?? [])..add(event);
    }
    return events;
  }

  /// Returns the list of events for the given day.
  List<dynamic> _getEventsForDay(DateTime day, Map<DateTime, List<dynamic>> events) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<FamilyDataV001>(context);
    final events = _buildEvents(data);
    final selectedEvents = _getEventsForDay(_selectedDay, events);

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
            eventLoader: (day) => _getEventsForDay(day, events),
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
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final item = selectedEvents[index];
                if (item is Task) {
                  return ListTile(
                    leading: const Icon(Icons.check_box),
                    title: Text(item.title),
                    subtitle: Text(item.description ?? ''),
                  );
                } else if (item is Event) {
                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(item.title),
                    subtitle: Text(item.description ?? ''),
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