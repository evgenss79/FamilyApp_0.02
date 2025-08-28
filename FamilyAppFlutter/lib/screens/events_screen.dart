import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../screens/add_event_screen.dart';

/// Screen displaying a list of events from the family data provider.
///
/// Shows a list of scheduled events including their date/time and optional
/// description. A floating action button opens a form to add a new event.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyData>(
      builder: (context, data, _) {
        final events = data.events;
        return Scaffold(
          appBar: AppBar(title: const Text('Events')),
          body: events.isEmpty
              ? const Center(child: Text('No events scheduled yet.'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(event.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${event.date.toLocal().toString().substring(0, 16)}'),
                          if (event.description != null && event.description!.isNotEmpty)
                            Text(event.description!),
                        ],
                      ),
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
              Navigator.of(context).push(
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
