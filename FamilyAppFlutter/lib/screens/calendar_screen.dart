import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/event.dart';
import '../models/task.dart';

/// Displays a simple aggregated view of upcoming events and tasks.  Events
/// and tasks are listed sequentially without calendar visualization.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          final List<Widget> children = [];
          if (data.events.isNotEmpty) {
            children.add(const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ));
            children.addAll(data.events.map((Event e) {
              return ListTile(
                title: Text(e.title ?? ''),
                subtitle: Text(e.startDateTime?.toString() ?? ''),
              );
            }));
          }
          if (data.tasks.isNotEmpty) {
            children.add(const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ));
            children.addAll(data.tasks.map((Task t) {
              return ListTile(
                title: Text(t.title ?? ''),
                subtitle: Text(t.dueDate?.toString() ?? ''),
              );
            }));
          }
          return ListView(
            children: children.isNotEmpty
                ? children
                : [const Center(child: Text('No events or tasks'))],
          );
        },
      ),
    );
  }
}