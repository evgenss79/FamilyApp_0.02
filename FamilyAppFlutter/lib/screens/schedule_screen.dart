import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/schedule_data.dart';
import '../models/schedule_item.dart';

/// Displays a list of scheduled items.  Each item shows its title and
/// date/time.  New items can be added via some other screen.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Consumer<ScheduleData>(
        builder: (context, data, _) {
          if (data.items.isEmpty) {
            return const Center(child: Text('No scheduled items.'));
          }
          return ListView.builder(
            itemCount: data.items.length,
            itemBuilder: (context, index) {
              final ScheduleItem item = data.items[index];
              return ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(item.title),
                subtitle: Text(item.dateTime.toString()),
              );
            },
          );
        },
      ),
    );
  }
}