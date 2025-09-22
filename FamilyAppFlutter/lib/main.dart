import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/chat_provider.dart';
import 'providers/family_data.dart';
import 'providers/friends_data.dart';
import 'providers/gallery_data.dart';
import 'providers/language_provider.dart';
import 'providers/schedule_data.dart';
import 'screens/home_screen.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'storage/hive_secure.dart';


/// Entry point for the Family App. Initializes Firebase, Hive and all
/// services required by the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await HiveSecure.ensureDek();

  final settingsBox = await Hive.openBox('settings');

  final firestore = FirestoreService();
  final storage = StorageService();
  final languageProvider = LanguageProvider(box: settingsBox);

  runApp(
    MyApp(
      firestore: firestore,
      storage: storage,
      languageProvider: languageProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.firestore,
    required this.storage,
    required this.languageProvider,
  });

  final FirestoreService firestore;
  final StorageService storage;
  final LanguageProvider languageProvider;


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: firestore),
        Provider<StorageService>.value(value: storage),

        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
        ),

        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(
            firestore: firestore,
            storage: storage,
            familyId: AppConfig.familyId,
          )..init(),
        ),
        ChangeNotifierProvider<FamilyData>(
          create: (_) => FamilyData(
            firestore: firestore,
            familyId: AppConfig.familyId,
          )..load(),
        ),
        ChangeNotifierProvider<FriendsData>(
          create: (_) => FriendsData(
            firestore: firestore,
            familyId: AppConfig.familyId,
          )..load(),
        ),
        ChangeNotifierProvider<GalleryData>(
          create: (_) => GalleryData(
            firestore: firestore,
            storage: storage,
            familyId: AppConfig.familyId,
          )..load(),
        ),
        ChangeNotifierProvider<ScheduleData>(
          create: (_) => ScheduleData(
            firestore: firestore,
            familyId: AppConfig.familyId,
          )..load(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, language, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            locale: language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            onGenerateTitle: (context) => context.tr('appTitle'),
            home: const HomeScreen(),
          );
        },

      ),
    );
  }
}
