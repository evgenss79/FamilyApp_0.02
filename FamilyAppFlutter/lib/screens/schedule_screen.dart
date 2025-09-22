import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(title: const Text('Schedule')),
      body: Consumer2<ScheduleData, FamilyData>(
        builder: (context, scheduleData, familyData, _) {
          if (scheduleData.items.isEmpty) {
            return const Center(child: Text('No scheduled items.'));
          }
          final items = scheduleData.items.toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final ScheduleItem item = items[index];
              final memberName = familyData.memberById(item.memberId ?? '')?.name;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(item.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatRange(item)),
                      if (memberName != null && memberName.isNotEmpty)
                        Text('Member: $memberName'),
                      if (item.location?.isNotEmpty == true)
                        Text('Location: ${item.location}'),
                      if (item.notes?.isNotEmpty == true)
                        Text('Notes: ${item.notes}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatRange(ScheduleItem item) {
    final start = DateFormat('dd.MM.yyyy HH:mm').format(item.dateTime);
    final end = DateFormat('dd.MM.yyyy HH:mm').format(item.endDateTime);
    return '$start – $end';
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry'),
        content: const Text('Remove this item from the schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ScheduleData>().removeItem(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
