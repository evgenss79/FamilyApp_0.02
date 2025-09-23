import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/schedule_item.dart';
import '../providers/family_data.dart';
import '../providers/schedule_data.dart';
import 'add_schedule_item_screen.dart';

/// Displays a list of scheduled items.  Each item shows its title,
/// time range and linked member.  New items can be added via the
/// floating action button.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('schedule'))),
      body: Consumer2<ScheduleData, FamilyData>(
        builder: (context, scheduleData, familyData, _) {
          if (scheduleData.isLoading && scheduleData.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (scheduleData.items.isEmpty) {
            return Center(child: Text(context.tr('noScheduleItemsLabel')));
          }
          final items = scheduleData.items.toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final ScheduleItem item = items[index];
              final memberName =
                  familyData.memberById(item.memberId ?? '')?.name ?? '';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(item.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.loc.formatDateRange(
                        item.dateTime,
                        item.endDateTime,
                      )),
                      if (memberName.isNotEmpty)
                        Text(
                          '${context.tr('scheduleMemberLabel')}: $memberName',
                        ),
                      if (item.location?.isNotEmpty == true)
                        Text(
                          '${context.tr('scheduleLocationLabel')}: ${item.location}',
                        ),
                      if (item.notes?.isNotEmpty == true)
                        Text(
                          '${context.tr('scheduleNotesLabel')}: ${item.notes}',
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: context.tr('deleteScheduleAction'),
                    onPressed: () => _confirmDelete(context, item.id),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddScheduleItemScreen()),
          );
        },
        tooltip: context.tr('addScheduleItemTitle'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deleteScheduleAction')),
        content: Text(context.tr('deleteScheduleMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancelAction')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<ScheduleData>().removeItem(id);
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
