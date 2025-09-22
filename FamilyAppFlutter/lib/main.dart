import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/chat_provider.dart';
import 'providers/family_data.dart';
import 'providers/friends_data.dart';
import 'providers/gallery_data.dart';
import 'providers/language_provider.dart';
import 'providers/schedule_data.dart';
import 'screens/home_screen.dart';

/// Entry point for the Family App. The root widget wires up all
/// providers so the different feature screens can access shared state.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox('settings');
  final chatProvider = ChatProvider();
  await chatProvider.init();
  final languageProvider = LanguageProvider(box: settingsBox);
  runApp(
    MyApp(
      chatProvider: chatProvider,
      languageProvider: languageProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ChatProvider chatProvider;
  final LanguageProvider languageProvider;

  const MyApp({
    super.key,
    required this.chatProvider,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider(create: (_) => FamilyData()),
        ChangeNotifierProvider(create: (_) => FriendsData()),
        ChangeNotifierProvider(create: (_) => GalleryData()),
        ChangeNotifierProvider(create: (_) => ScheduleData()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, language, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.l10n.t('appTitle'),
            locale: language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
