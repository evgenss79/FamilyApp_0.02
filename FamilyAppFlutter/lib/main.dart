import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bootstrap.dart';
import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/chat_provider.dart';
import 'providers/family_data.dart';
import 'providers/friends_data.dart';
import 'providers/gallery_data.dart';
import 'providers/language_provider.dart';
import 'providers/schedule_data.dart';
import 'repositories/call_messages_repository.dart';
import 'repositories/calls_repository.dart';
import 'repositories/chat_messages_repository.dart';
import 'repositories/chats_repository.dart';
import 'repositories/events_repository.dart';
import 'repositories/friends_repository.dart';
import 'repositories/gallery_repository.dart';
import 'repositories/members_repository.dart';
import 'repositories/schedule_repository.dart';
import 'repositories/tasks_repository.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'storage/local_store.dart';

/// Entry point for the Family App. Initializes Firebase, Hive and all
/// services required by the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(); // ANDROID-ONLY FIX: serialized Android bootstrap flow.

  final StorageService storage = StorageService();
  final MembersRepository membersRepository = MembersRepository();
  final TasksRepository tasksRepository = TasksRepository();
  final EventsRepository eventsRepository = EventsRepository();
  final FriendsRepository friendsRepository = FriendsRepository();
  final GalleryRepository galleryRepository = GalleryRepository();
  final ScheduleRepository scheduleRepository = ScheduleRepository();
  final ChatsRepository chatsRepository = ChatsRepository();
  final ChatMessagesRepository chatMessagesRepository =
      ChatMessagesRepository();
  final CallsRepository callsRepository = CallsRepository();
  final CallMessagesRepository callMessagesRepository =
      CallMessagesRepository();
  final LanguageProvider languageProvider =
      LanguageProvider(box: LocalStore.settingsBox);

  final SyncService syncService = SyncService(
    familyId: AppConfig.familyId,
    membersRepository: membersRepository,
    tasksRepository: tasksRepository,
    eventsRepository: eventsRepository,
    friendsRepository: friendsRepository,
    galleryRepository: galleryRepository,
    scheduleRepository: scheduleRepository,
    chatsRepository: chatsRepository,
    chatMessagesRepository: chatMessagesRepository,
    callsRepository: callsRepository,
    callMessagesRepository: callMessagesRepository,
  );
  await syncService.start();
  await syncService.flush();

  runApp(
    MyApp(
      storage: storage,
      languageProvider: languageProvider,
      membersRepository: membersRepository,
      tasksRepository: tasksRepository,
      eventsRepository: eventsRepository,
      friendsRepository: friendsRepository,
      galleryRepository: galleryRepository,
      scheduleRepository: scheduleRepository,
      chatsRepository: chatsRepository,
      chatMessagesRepository: chatMessagesRepository,
      syncService: syncService,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.storage,
    required this.languageProvider,
    required this.membersRepository,
    required this.tasksRepository,
    required this.eventsRepository,
    required this.friendsRepository,
    required this.galleryRepository,
    required this.scheduleRepository,
    required this.chatsRepository,
    required this.chatMessagesRepository,
    required this.syncService,
  });

  final StorageService storage;
  final LanguageProvider languageProvider;
  final MembersRepository membersRepository;
  final TasksRepository tasksRepository;
  final EventsRepository eventsRepository;
  final FriendsRepository friendsRepository;
  final GalleryRepository galleryRepository;
  final ScheduleRepository scheduleRepository;
  final ChatsRepository chatsRepository;
  final ChatMessagesRepository chatMessagesRepository;
  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(
            chatsRepository: chatsRepository,
            messagesRepository: chatMessagesRepository,
            storage: storage,
            syncService: syncService,
            familyId: AppConfig.familyId,
          )..init(),
        ),
        ChangeNotifierProvider<FamilyData>(
          create: (_) => FamilyData(
            familyId: AppConfig.familyId,
            membersRepository: membersRepository,
            tasksRepository: tasksRepository,
            eventsRepository: eventsRepository,
            syncService: syncService,
          )..load(),
        ),
        ChangeNotifierProvider<FriendsData>(
          create: (_) => FriendsData(
            repository: friendsRepository,
            syncService: syncService,
            familyId: AppConfig.familyId,
          )..load(),
        ),
        ChangeNotifierProvider<GalleryData>(
          create: (_) => GalleryData(
            repository: galleryRepository,
            storage: storage,
            syncService: syncService,
            familyId: AppConfig.familyId,
          )..load(),
        ),
        ChangeNotifierProvider<ScheduleData>(
          create: (_) => ScheduleData(
            repository: scheduleRepository,
            syncService: syncService,
            familyId: AppConfig.familyId,
          )..load(),
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
