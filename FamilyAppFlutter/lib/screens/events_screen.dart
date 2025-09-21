import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/event.dart';
import 'add_event_screen.dart';

/// Shows all events in the family calendar.  Users can view basic
/// event information and add new events using the floating action
/// button.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final events = data.events;
          if (events.isEmpty) {
            return const Center(child: Text('No events added yet.'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: const Icon(Icons.event),
                title: Text(event.title ?? ''),
                subtitle: Text(event.startDateTime?.toString() ?? ''),
              );
            },
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
  }
}