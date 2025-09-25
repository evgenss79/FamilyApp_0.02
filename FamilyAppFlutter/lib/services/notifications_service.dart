import 'dart:developer' as developer;

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

  Future<void> init() async {
    // ANDROID-ONLY FIX: configure combined local + push notifications stack.
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _messaging.setAutoInitEnabled(true);

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        await LocalStore.saveFcmToken(token);
      }
    } catch (error, stackTrace) {
      developer.log('Unable to register FCM token',
          name: 'NotificationsService', error: error, stackTrace: stackTrace);
    }

    _messaging.onTokenRefresh.listen((String token) async {
      await LocalStore.saveFcmToken(token);
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _localNotifications.initialize(settings);
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

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'FamilyApp',
      notification.body,
      details,
      payload: message.data['route'] as String?,
    );
  }
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

  await plugin.show(
    notification.hashCode,
    notification.title ?? 'FamilyApp',
    notification.body,
    details,
    payload: message.data['route'] as String?,
  );
}
