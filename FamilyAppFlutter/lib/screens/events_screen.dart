import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/family_data.dart';
import 'add_event_screen.dart';

/// Shows all events in the family calendar.  Users can view event
/// information and add new events using the floating action button.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final List<Event> events = data.events;
          if (events.isEmpty) {
            return const Center(child: Text('No events added yet.'));
          }
          events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = events[index];
              final participants = event.participantIds
                  .map((id) => data.memberById(id)?.name ?? 'Unknown member')
                  .toList();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatRange(event.startDateTime, event.endDateTime)),
                      if (event.description?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(event.description!),
                        ),
                      if (participants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Participants: ${participants.join(', ')}'),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete event',
                    onPressed: () => _confirmDelete(context, event),
                  ),
                ),
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

  String _formatRange(DateTime start, DateTime end) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');
    return '${formatter.format(start)} – ${formatter.format(end)}';
  }

  void _confirmDelete(BuildContext context, Event event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event'),
        content: Text('Delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FamilyData>().removeEvent(event.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
