import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/chat.dart';
import 'providers/family_data.dart';
import 'providers/chat_provider.dart';
import 'providers/friends_data.dart';
import 'providers/gallery_data.dart';
import 'providers/schedule_data.dart';
import 'screens/members_screen.dart';

/// Entry point for the Family App.  Sets up providers and launches
/// the root widget.  For demonstration purposes the home screen is
/// the [MembersScreen]; navigation to other screens can be added
/// as needed.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final chatProvider = ChatProvider();
  await chatProvider.init();
  runApp(MyApp(chatProvider: chatProvider));
}

class MyApp extends StatelessWidget {
  final ChatProvider chatProvider;
  const MyApp({super.key, required this.chatProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ChangeNotifierProvider(create: (_) => FamilyData()),
        ChangeNotifierProvider(create: (_) => FriendsData()),
        ChangeNotifierProvider(create: (_) => GalleryData()),
        ChangeNotifierProvider(create: (_) => ScheduleData()),
      ],
      child: MaterialApp(
        title: 'Family App',
        theme: ThemeData.light(),
        home: const MembersScreen(),
      ),
    );
  }
}