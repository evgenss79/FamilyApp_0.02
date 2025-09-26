import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ANDROID-ONLY FIX: centralized bootstrap injects Firebase/config without direct AppConfig wiring.
import 'bootstrap.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/family_data.dart';
import 'providers/friends_data.dart';
import 'providers/gallery_data.dart';
import 'providers/language_provider.dart';
import 'providers/schedule_data.dart';

import 'models/chat.dart';

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
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/sign_in_screen.dart';

import 'screens/chat_screen.dart';

import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/notifications_service.dart';
import 'services/remote_config_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(); // ANDROID-ONLY FIX: serialized Android bootstrap flow.
  runApp(const FamilyApp());
}

class FamilyApp extends StatefulWidget {
  const FamilyApp({super.key});

  @override
  State<FamilyApp> createState() => _FamilyAppState();
}

class _FamilyAppState extends State<FamilyApp> {
  late final StorageService _storage;

  @override
  void initState() {
    super.initState();
    _storage = StorageService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: _storage),
        ChangeNotifierProvider<RemoteConfigService>.value(
          value: RemoteConfigService.instance,
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(box: LocalStore.settingsBox),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: AuthService(),
            notificationsService: NotificationsService.instance,
          ),
        ),
      ],
      child: Consumer2<LanguageProvider, AuthProvider>(
        builder: (
          BuildContext context,
          LanguageProvider language,
          AuthProvider auth,
          _,
        ) {
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
            home: _AuthRouter(storage: _storage, status: auth.status),
          );
        },
      ),
    );
  }
}

class _AuthRouter extends StatelessWidget {
  const _AuthRouter({
    required this.storage,
    required this.status,
  });

  final StorageService storage;
  final AuthStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
        return const SignInScreen();
      case AuthStatus.needsProfile:
        return const CompleteProfileScreen();
      case AuthStatus.authenticated:
        return _AuthenticatedScope(storage: storage);
    }
  }
}

class _AuthenticatedScope extends StatefulWidget {
  const _AuthenticatedScope({required this.storage});

  final StorageService storage;

  @override
  State<_AuthenticatedScope> createState() => _AuthenticatedScopeState();
}

class _AuthenticatedScopeState extends State<_AuthenticatedScope> {
  final MembersRepository _membersRepository = MembersRepository();
  final TasksRepository _tasksRepository = TasksRepository();
  final EventsRepository _eventsRepository = EventsRepository();
  final FriendsRepository _friendsRepository = FriendsRepository();
  final GalleryRepository _galleryRepository = GalleryRepository();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final ChatsRepository _chatsRepository = ChatsRepository();
  final ChatMessagesRepository _chatMessagesRepository =
      ChatMessagesRepository();
  final CallsRepository _callsRepository = CallsRepository();
  final CallMessagesRepository _callMessagesRepository =
      CallMessagesRepository();
  final NotificationsService _notifications = NotificationsService.instance;

  SyncService? _syncService;
  bool _initializing = true;
  String? _activeFamilyId;
  StreamSubscription<String>? _notificationSubscription;
  String? _pendingNotificationPayload;

  @override
  void initState() {
    super.initState();
    _notificationSubscription =
        _notifications.payloadStream.listen(_handleNotificationPayload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSync();
    });
  }

  Future<void> _startSync() async {
    final String? familyId = context.read<AuthProvider>().familyId;
    if (familyId == null) {
      return;
    }
    if (_activeFamilyId == familyId && _syncService != null) {
      setState(() {
        _initializing = false;
      });
      return;
    }
    setState(() {
      _initializing = true;
    });
    await _syncService?.dispose();
    final SyncService syncService = SyncService(
      familyId: familyId,
      membersRepository: _membersRepository,
      tasksRepository: _tasksRepository,
      eventsRepository: _eventsRepository,
      friendsRepository: _friendsRepository,
      galleryRepository: _galleryRepository,
      scheduleRepository: _scheduleRepository,
      chatsRepository: _chatsRepository,
      chatMessagesRepository: _chatMessagesRepository,
      callsRepository: _callsRepository,
      callMessagesRepository: _callMessagesRepository,
    );
    await syncService.start();
    await syncService.flush();
    if (!mounted) {
      await syncService.dispose();
      return;
    }
    setState(() {
      _syncService = syncService;
      _initializing = false;
      _activeFamilyId = familyId;
    });
    final String? pendingPayload = _pendingNotificationPayload;
    if (pendingPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final String payload = pendingPayload;
        _pendingNotificationPayload = null;
        unawaited(_openChatFromPayload(payload));
      });
    }
  }

  @override
  void dispose() {
    final Future<void>? disposeFuture = _syncService?.dispose();
    if (disposeFuture != null) {
      unawaited(disposeFuture);
    }
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing || _syncService == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final String familyId = context.watch<AuthProvider>().familyId!;
    if (_activeFamilyId != familyId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSync();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final SyncService syncService = _syncService!;

    return MultiProvider(
      providers: [
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider<ChatProvider>(
          key: ValueKey<String>('chat-$familyId'),
          create: (_) => ChatProvider(
            chatsRepository: _chatsRepository,
            messagesRepository: _chatMessagesRepository,
            storage: widget.storage,
            syncService: syncService,
            notificationsService: _notifications,
            familyId: familyId,
          )..init(),
        ),
        ChangeNotifierProvider<FamilyData>(
          key: ValueKey<String>('family-$familyId'),
          create: (_) => FamilyData(
            familyId: familyId,
            membersRepository: _membersRepository,
            tasksRepository: _tasksRepository,
            eventsRepository: _eventsRepository,
            syncService: syncService,
          )..load(),
        ),
        ChangeNotifierProvider<FriendsData>(
          key: ValueKey<String>('friends-$familyId'),
          create: (_) => FriendsData(
            repository: _friendsRepository,
            syncService: syncService,
            familyId: familyId,
          )..load(),
        ),
        ChangeNotifierProvider<GalleryData>(
          key: ValueKey<String>('gallery-$familyId'),
          create: (_) => GalleryData(
            repository: _galleryRepository,
            storage: widget.storage,
            syncService: syncService,
            familyId: familyId,
          )..load(),
        ),
        ChangeNotifierProvider<ScheduleData>(
          key: ValueKey<String>('schedule-$familyId'),
          create: (_) => ScheduleData(
            repository: _scheduleRepository,
            syncService: syncService,
            familyId: familyId,
          )..load(),
        ),
      ],
      child: const HomeScreen(),
    );
  }

  void _handleNotificationPayload(String payload) {
    if (!mounted || _initializing || _syncService == null) {
      _pendingNotificationPayload = payload;
      return;
    }
    _pendingNotificationPayload = null;
    unawaited(_openChatFromPayload(payload));
  }

  Future<void> _openChatFromPayload(String payload) async {
    if (!mounted) {
      _pendingNotificationPayload = payload;
      return;
    }
    if (!payload.startsWith('chat:')) {
      return;
    }
    final String chatId = payload.substring('chat:'.length);
    ChatProvider chatProvider;
    try {
      chatProvider = context.read<ChatProvider>();
    } catch (_) {
      _pendingNotificationPayload = payload;
      return;
    }
    Chat? chat;
    try {
      chat = chatProvider.chats.firstWhere((Chat item) => item.id == chatId);
    } catch (_) {
      chat = null;
    }
    if (chat == null) {
      await chatProvider.load();
      try {
        chat = chatProvider.chats.firstWhere((Chat item) => item.id == chatId);
      } catch (_) {
        chat = null;
      }
    }
    if (chat == null || !mounted) {
      return;
    }
    final Chat target = chat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(chat: target)),
      );
    });
  }
}
