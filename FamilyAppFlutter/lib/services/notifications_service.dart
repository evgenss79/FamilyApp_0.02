import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import '../storage/local_store.dart';

class NotificationsService {
  NotificationsService._();

  static final NotificationsService instance = NotificationsService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _payloadController =
      StreamController<String>.broadcast();

  String? _activeFamilyId;
  final Set<String> _chatTopics = <String>{};

  Stream<String> get payloadStream => _payloadController.stream;

  Future<void> init() async {
    // ANDROID-ONLY FIX: configure combined local + push notifications stack.
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _messaging.setAutoInitEnabled(true);

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteNavigation);

    final NotificationAppLaunchDetails? launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationPayload(launchDetails!.notificationResponse?.payload);
    }

    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteNavigation(initialMessage);
    }

    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        await LocalStore.saveFcmToken(token);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Unable to register FCM token',
        name: 'NotificationsService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _messaging.onTokenRefresh.listen((String token) async {
      await LocalStore.saveFcmToken(token);
    });
  }

  Future<void> syncTokenToMember({
    required String familyId,
    required String memberId,
  }) async {
    final String? token = LocalStore.getFcmToken();
    if (token == null || token.isEmpty) {
      return;
    }
    final DocumentReference<Map<String, dynamic>> memberRef = FirebaseFirestore
        .instance
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId);
    try {
      // ANDROID-ONLY FIX: mirror the Android device token in the encrypted profile.
      await memberRef.set(<String, dynamic>{
        'fcmTokens': FieldValue.arrayUnion(<String>[token]),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      developer.log(
        'Unable to sync FCM token',
        name: 'NotificationsService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setActiveFamily(String familyId) async {
    if (_activeFamilyId == familyId) {
      return;
    }
    if (_activeFamilyId != null && _activeFamilyId != familyId) {
      await _unsubscribeFamilyTopics(_activeFamilyId!);
    }
    final String topic = _familyTopic(familyId);
    try {
      // ANDROID-ONLY FIX: subscribe Android devices to family-level fan-out topics.
      await _messaging.subscribeToTopic(topic);
      _activeFamilyId = familyId;
    } catch (error, stackTrace) {
      developer.log(
        'Unable to subscribe to family topic',
        name: 'NotificationsService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> subscribeToChatTopic({
    required String familyId,
    required String chatId,
  }) async {
    await setActiveFamily(familyId);
    final String topic = _chatTopic(familyId, chatId);
    if (_chatTopics.contains(topic)) {
      return;
    }
    try {
      // ANDROID-ONLY FIX: register chat topics so Android receives direct pushes for each room.
      await _messaging.subscribeToTopic(topic);
      _chatTopics.add(topic);
    } catch (error, stackTrace) {
      developer.log(
        'Unable to subscribe to chat topic',
        name: 'NotificationsService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> unsubscribeFromChatTopic({
    required String familyId,
    required String chatId,
  }) async {
    final String topic = _chatTopic(familyId, chatId);
    if (!_chatTopics.remove(topic)) {
      return;
    }
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (error, stackTrace) {
      developer.log(
        'Unable to unsubscribe from chat topic',
        name: 'NotificationsService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearFamilyContext() async {
    if (_activeFamilyId == null && _chatTopics.isEmpty) {
      return;
    }
    final String? familyId = _activeFamilyId;
    if (familyId != null) {
      await _unsubscribeFamilyTopics(familyId);
    }
    for (final String topic in _chatTopics.toList()) {
      try {
        await _messaging.unsubscribeFromTopic(topic);
      } catch (error, stackTrace) {
        developer.log(
          'Unable to unsubscribe from chat topic',
          name: 'NotificationsService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _chatTopics.clear();
    _activeFamilyId = null;
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationPayload(response.payload);
      },
    );

    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'familyapp_default',
      'FamilyApp Notifications',
      description: 'Default notification channel for FamilyApp alerts.',
      importance: Importance.high,
    );
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(defaultChannel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) {
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'familyapp_default',
      'FamilyApp Notifications',
      channelDescription: 'Default notification channel for FamilyApp alerts.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );


    final String? payload = _extractPayload(message);
    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'FamilyApp',
      notification.body,
      details,
      payload: payload,
    );
  }

  void _handleRemoteNavigation(RemoteMessage message) {
    _handleNotificationPayload(_extractPayload(message));
  }

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    _payloadController.add(payload);
  }

  Future<void> _unsubscribeFamilyTopics(String familyId) async {
    final String topic = _familyTopic(familyId);
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (error, stackTrace) {
      developer.log(
        'Unable to unsubscribe from family topic',
        name: 'NotificationsService',
        error: error,
        stackTrace: stackTrace,
      );
    }
    for (final String topic in _chatTopics.toList()) {
      try {
        await _messaging.unsubscribeFromTopic(topic);
      } catch (error, stackTrace) {
        developer.log(
          'Unable to unsubscribe from chat topic',
          name: 'NotificationsService',
          error: error,
          stackTrace: stackTrace,
        );
      }
      _chatTopics.remove(topic);
    }
  }

  String _familyTopic(String familyId) => 'family_$familyId';

  String _chatTopic(String familyId, String chatId) =>
      'family_${familyId}_chat_$chatId';
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    // ANDROID-ONLY FIX: background isolate needs its own Firebase bootstrap.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );
  await plugin.initialize(settings);

  final RemoteNotification? notification = message.notification;
  if (notification == null) {
    return;
  }

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'familyapp_default',
    'FamilyApp Notifications',
    channelDescription: 'Default notification channel for FamilyApp alerts.',
    importance: Importance.high,
    priority: Priority.high,
  );
  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  final String? payload = _extractPayload(message);
  await plugin.show(
    notification.hashCode,
    notification.title ?? 'FamilyApp',
    notification.body,
    details,
    payload: payload,
  );
}

String? _extractPayload(RemoteMessage message) {
  final Map<String, dynamic> data = message.data;
  final Object? explicit = data['payload'] ?? data['route'];
  if (explicit is String && explicit.isNotEmpty) {
    return explicit;
  }
  final Object? chatId = data['chatId'];
  if (chatId is String && chatId.isNotEmpty) {
    return 'chat:$chatId';
  }
  return null;
}
