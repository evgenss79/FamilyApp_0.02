import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/event.dart';
import 'add_event_screen.dart';

/// Displays a list of family events sorted by date.  Allows users to add
/// and remove events.  Uses the [FamilyDataV001] provider to read and
/// modify the list of events.
class EventsScreenV001 extends StatelessWidget {
  const EventsScreenV001({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        // Cast the raw events list from the provider to a strongly-typed
        // `List<Event>` so that Dart knows `date` exists on each item. Without
        // this cast the events would be treated as `List<Object?>` which
        // prevents using the `date` getter below.
        final events = List<Event>.from(data.events);

        // Sort events chronologically by start date/time.  The `startDateTime`
        // field is non-nullable so comparisons are safe.  This will order
        // events by their starting moment.
        events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Events'),
          ),
          body: events.isEmpty
              ? const Center(child: Text('No events yet.'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final start = event.startDateTime;
                    final end = event.endDateTime;
                    final startString = '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year} '
                        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                    final endString = '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year} '
                        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                    // Compose time range string.  If start and end are equal, show only one.
                    final timeRange = start.isAtSameMomentAs(end)
                        ? startString
                        : '$startString - $endString';
                    final desc = event.description ?? '';
                    final subtitleParts = <String>[];
                    if (desc.isNotEmpty) subtitleParts.add(desc);
                    subtitleParts.add(timeRange);
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(subtitleParts.join('\n')),
                      isThreeLine: subtitleParts.length > 1,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          data.removeEvent(event);
                        },
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEventScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}