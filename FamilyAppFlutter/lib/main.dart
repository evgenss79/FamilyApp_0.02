iimport 'package:flutter/material.dart';
import 'package:provider/provider.dart';
mmport 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

  import 'services/storage_service.dart';
import 'providers/family_data.dart';
import 'screens/members_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/events_screen.dart';
import 'services/chat_storage_service.dart';
import 'providers/chat_data.dart';
import 'screens/schedule_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/chat_list_screen.dart';
  import 'screens/chat_list_screen_v2.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await StorageServiceV001.init();
  await ChatStorageServiceV001.init();
  final familyData = FamilyDataV001();
  final chatData = ChatDataV001();
  await familyData.loadFromStorage();
  await chatData.loadData();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FamilyDataV001>.value(value: familyData),
        ChangeNotifierProvider<ChatDataV001>.value(value: chatData),
      ],
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const screens = [
      MembersScreenV001(),
      TasksScreenV001(),
      EventsScreenV001(),
      ChatListScreenV2(),
      ScheduleScreenV001(),
      CalendarScreenV001(),
    ];
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
