import 'package:flutter/material.dart';

import 'models/family_member.dart';
import 'models/task.dart';
import 'models/event.dart';
import 'screens/members_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/events_screen.dart';

/// Entry point for the cross‑platform FamilyApp built with Flutter.
void main() {
  runApp(const FamilyApp());
}

/// Root widget wrapping the entire application.
class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeTabs(),
    );
  }
}

/// Stateful widget managing bottom navigation between the main screens.
class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _currentIndex = 0;

  // List of tab widgets displayed in the bottom navigation bar.
  final List<Widget> _tabs = const [
    MembersScreen(),
    TasksScreen(),
    EventsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
        ],
      ),
    );
  }
}
