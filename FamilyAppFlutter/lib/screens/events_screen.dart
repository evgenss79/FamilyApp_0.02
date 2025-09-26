import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
      appBar: AppBar(title: Text(context.tr('events'))),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final List<Event> events = data.events.toList()
            ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
          if (data.isLoading && events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (events.isEmpty) {
            return Center(child: Text(context.tr('noEventsLabel')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = events[index];
              final participants = event.participantIds
                  .map((id) => data.memberById(id)?.name ?? context.tr('unknownMemberLabel'))
                  .where((name) => name.isNotEmpty)
                  .toList();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc
                            .formatDateRange(event.startDateTime, event.endDateTime),
                      ),
                      if (event.description?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(event.description!),
                        ),
                      if (participants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${context.tr('participantsLabel')}: ${participants.join(', ')}',
                          ),
                        ),
                      if (event.locationLabel != null ||
                          (event.latitude != null && event.longitude != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.place, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.locationLabel ??
                                      '${event.latitude!.toStringAsFixed(4)}, ${event.longitude!.toStringAsFixed(4)}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (event.reminderEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                context.loc.eventReminderMinutes(
                                  event.reminderMinutesBefore ?? 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: context.tr('deleteEventAction'),
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
        tooltip: context.tr('addEventTitle'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Event event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deleteEventAction')),
        content: Text(context.loc.confirmDelete(event.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancelAction')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<FamilyData>().removeEvent(event.id);
              if (context.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Text(context.tr('deleteAction')),
          ),
        ],
      ),
    );
  }
}
