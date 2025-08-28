import 'package:flutter/material.dart';
import '../models/event.dart';

/// Screen displaying a list of events.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder list of events. Later this will come from a data store or backend.
    final List<Event> events = [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: events.isEmpty
          ? const Center(child: Text('No events scheduled yet.'))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(event.title),
                  subtitle: Text(event.date.toLocal().toString()),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to add event screen / show dialog.
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
