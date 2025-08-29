import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'providers/family_data.dart';
import 'screens/members_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/events_screen.dart';
import 'screens/schedule_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageServiceV001.init();
  final familyData = FamilyDataV001();
  await familyData.loadFromStorage();
  runApp(
    ChangeNotifierProvider.value(
      value: familyData,
      child: const FamilyAppV001(),
    ),
  );
}

class FamilyAppV001 extends StatelessWidget {
  const FamilyAppV001({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family App',
      home: const HomeTabsV001(),
    );
  }
}

class HomeTabsV001 extends StatefulWidget {
  const HomeTabsV001({super.key});

  @override
  State<HomeTabsV001> createState() => _HomeTabsV001State();
}

class _HomeTabsV001State extends State<HomeTabsV001> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    MembersScreenV001(),
    TasksScreenV001(),
    EventsScreenV001(),
    ScheduleScreenV001(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
        ],
      ),
    );
  }
}
