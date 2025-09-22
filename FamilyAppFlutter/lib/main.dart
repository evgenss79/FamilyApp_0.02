import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/chat_provider.dart';
import 'providers/family_data.dart';
import 'providers/friends_data.dart';
import 'providers/gallery_data.dart';
import 'providers/schedule_data.dart';
import 'screens/home_screen.dart';

/// Entry point for the Family App. The root widget wires up all
/// providers so the different feature screens can access shared state.
Future<void> main() async {
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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
