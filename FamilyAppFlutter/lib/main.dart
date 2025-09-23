import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/chat_provider.dart';
import 'providers/family_data.dart';
import 'providers/friends_data.dart';
import 'providers/gallery_data.dart';
import 'providers/language_provider.dart';
import 'providers/schedule_data.dart';
import 'screens/home_screen.dart';
import 'services/encryption_service.dart';
import 'services/firebase_service.dart';
import 'services/firestore_service.dart';
import 'services/migration_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final FirebaseService firebaseService = FirebaseService();
  await firebaseService.initialize();

  final EncryptionService encryptionService = EncryptionService();
  await encryptionService.ensureKey();

  final FirestoreService firestoreService = FirestoreService(
    firestore: firebaseService.firestore,
    encryptionService: encryptionService,
  );
  await firestoreService.replayPendingOperations();

  final MigrationService migrationService = MigrationService(
    firestore: firestoreService,
  );
  await migrationService.migrateLegacyHiveData(AppConfig.familyId);

  final StorageService storageService = StorageService();
  final Box<Object?> settingsBox = await Hive.openBox<Object?>('settings');
  final LanguageProvider languageProvider = LanguageProvider(box: settingsBox);

  runApp(
    MyApp(
      firestore: firestoreService,
      storage: storageService,
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
          )..init(),
        ),
        ChangeNotifierProvider<FriendsData>(
          create: (_) => FriendsData(
            firestore: firestore,
            familyId: AppConfig.familyId,
          )..init(),
        ),
        ChangeNotifierProvider<GalleryData>(
          create: (_) => GalleryData(
            firestore: firestore,
            storage: storage,
            familyId: AppConfig.familyId,
          )..init(),
        ),
        ChangeNotifierProvider<ScheduleData>(
          create: (_) => ScheduleData(
            firestore: firestore,
            familyId: AppConfig.familyId,
          )..init(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (BuildContext context, LanguageProvider language, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            locale: language.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            onGenerateTitle: (BuildContext context) => context.tr('appTitle'),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
