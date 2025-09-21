import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';

/// A unified schedule screen combining tasks and events for version 0.01.
///
/// Tasks with a due date and all events are collated into a single list,
/// sorted chronologically. Each item indicates whether it originates
/// from a task or an event and displays its title, an optional
/// description and the date/time.
class ScheduleScreenV001 extends StatefulWidget {
  const ScheduleScreenV001({super.key});

  @override
  State<ScheduleScreenV001> createState() => _ScheduleScreenV001State();
}

class _ScheduleScreenV001State extends State<ScheduleScreenV001> {
  // Type filter: 'All', 'Task', or 'Event'.
  String _filter = 'All';
  final List<String> _filters = ['All', 'Task', 'Event'];

  // Additional filters for date and member.
  DateTime? _selectedDay;
  String? _selectedMemberId;

  /// Helper to check if a schedule item is associated with the given member.
  ///
  /// If the item's [memberIds] list is empty, it is considered applicable to
  /// all members and thus returns true. Otherwise it returns true only when
  /// the provided [memberId] is contained in the list.
  bool _itemContainsMember(_ScheduleItem item, String memberId) {
    if (item.memberIds.isEmpty) return true;
    return item.memberIds.contains(memberId);
  }

  /// Builds the subtitle widget for a task item, formatting its description
  /// and end date/time on separate lines when needed.
  Widget _buildTaskSubtitle(_ScheduleItem item) {
    final parts = <String>[];
    if (item.description.isNotEmpty) {
      parts.add(item.description);
    }
    final d = item.date;
    final dateTimeString =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    parts.add(dateTimeString);
    return Text(parts.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        // Build a unified list of schedule entries from tasks and events.
        final List<_ScheduleItem> items = [];

        // Include tasks that have an end date/time (due date). Assign memberIds accordingly.
        for (final task in data.tasks) {
          if (task.endDateTime != null) {
            items.add(
              _ScheduleItem(
                title: task.title,
                description: task.description ?? '',
                date: task.endDateTime!,
                type: 'Task',
                memberIds: task.assignedMemberId != null
                    ? [task.assignedMemberId!]
                    : <String>[],
              ),
            );
          }
        }

        // Include events; use startDateTime as the schedule date and attach participantIds.
        for (final event in data.events) {
          final start = event.startDateTime;
          final end = event.endDateTime;
          final startString =
              '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
          final endString =
              '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year} ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
          final rangeString = start.isAtSameMomentAs(end)
              ? startString
              : '$startString - $endString';
          final desc = event.description != null && event.description!.isNotEmpty
              ? '${event.description!}\n$rangeString'
              : rangeString;
          items.add(
            _ScheduleItem(
              title: event.title,
              description: desc,
              date: start,
              type: 'Event',
              memberIds: event.participantIds,
            ),
          );
        }

        // Sort the items by date ascending.
        items.sort((a, b) => a.date.compareTo(b.date));

        // Apply selected filters: type, member, and date.
        final filteredItems = items.where((item) {
          // Type filter
          if (_filter != 'All' && item.type != _filter) {
            return false;
          }
          // Member filter
          if (_selectedMemberId != null) {
            if (item.memberIds.isNotEmpty &&
                !_itemContainsMember(item, _selectedMemberId!)) {
              return false;
            }
          }
          // Date filter
          if (_selectedDay != null) {
            final d = _selectedDay!;
            if (item.date.year != d.year ||
                item.date.month != d.month ||
                item.date.day != d.day) {
              return false;
            }
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Schedule')),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type filter dropdown
                    DropdownButton<String>(
                      value: _filter,
                      items: _filters
                          .map((f) => DropdownMenuItem<String>(
                                value: f,
                                child: Text(f),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _filter = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Member filter dropdown
                    DropdownButton<String?>(
                      value: _selectedMemberId,
                      hint: const Text('All members'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All members'),
                        ),
                        ...data.members.map((m) => DropdownMenuItem<String?>(
                              value: m.id,
                              child: Text(m.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMemberId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Date picker and clear button row
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDay == null
                                ? 'Select date'
                                : '${_selectedDay!.day.toString().padLeft(2, '0')}.${_selectedDay!.month.toString().padLeft(2, '0')}.${_selectedDay!.year}',
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDay ?? now,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(now.year + 5),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDay = picked;
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear date and member filters',
                          onPressed: () {
                            setState(() {
                              _selectedDay = null;
                              _selectedMemberId = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // List of filtered schedule items
              Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return ListTile(
                      leading: Icon(
                        item.type == 'Task' ? Icons.checklist : Icons.event,
                      ),
                      title: Text(item.title),
                      subtitle: item.type == 'Task'
                          ? _buildTaskSubtitle(item)
                          : Text(item.description),
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
  final List<String> memberIds;
  _ScheduleItem({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.memberIds = const <String>[],
  });
}