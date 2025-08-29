import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

iimport '../providers/family_data.dart';
import 'add_event_screen.dart';

class EventsScreenV001 extends StatelessWidget {
  const EventsScreenV001({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyDataV001>(
      builder: (context, data, child) {
        final events = List.from(data.events);
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
                        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                        : '';
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(
                        '${event.description.isNotEmpty ? event.description + '\n' : ''}$dateString',
                      ),
                      isThreeLine: event.description.isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          data.removeEvent(event.id);
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
