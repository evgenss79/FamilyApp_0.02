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

        // Sort events chronologically by their scheduled date/time. Compare
        // two event dates directly – since `Event.date` is non-nullable this
        // comparison is safe and eliminates runtime "getter not defined"
        // errors that would occur if the list contained `Object?` elements.
        events.sort((a, b) => a.date.compareTo(b.date));
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
                    final date = event.date;
                    final dateString = date != null
                        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                        : '';
                    // Safely handle the nullable description by assigning an empty
                    // string when it is null. This allows us to call `.isNotEmpty`
                    // and string concatenation without null checks scattered
                    // throughout the widget tree.  Using a local variable also
                    // improves readability of the ListTile below.
                    final desc = event.description ?? '';
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(
                        '${desc.isNotEmpty ? desc + '\n' : ''}$dateString',
                      ),
                      isThreeLine: desc.isNotEmpty,
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