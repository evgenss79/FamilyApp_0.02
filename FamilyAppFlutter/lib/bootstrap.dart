import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'security/secure_key_service.dart';
import 'services/analytics_service.dart';
import 'services/crashlytics_service.dart';
import 'services/notifications_service.dart';
import 'services/remote_config_service.dart';
import 'services/geo_reminders_service.dart';
import 'storage/local_store.dart';

Future<void> bootstrap() async {
  await _ensureFirebaseInitialized();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await SecureKeyService.ensureKey();
  await LocalStore.init();
  await NotificationsService.instance.init();
  await GeoRemindersService.instance
      .init(NotificationsService.instance); // ANDROID-ONLY FIX: boot geo reminders.

  // ANDROID-ONLY FIX: enable Crashlytics + Analytics pipelines for Android release telemetry.
  await CrashlyticsService.instance.init();
  await AnalyticsService.instance.init();

  // ANDROID-ONLY FIX: hydrate Remote Config before rendering Android UI gates.
  await RemoteConfigService.instance.init();
}

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isEmpty) {
    // ANDROID-ONLY FIX: initialize Firebase for the Android-only target.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    Firebase.app();
  }
}
