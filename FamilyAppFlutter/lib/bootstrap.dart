import 'package:cloud_firestore/cloud_firestore.dart';
import 'security/secure_key_service.dart';
import 'services/analytics_service.dart';
import 'services/crashlytics_service.dart';
import 'services/notifications_service.dart';
import 'services/remote_config_service.dart';
import 'services/geo_reminders_service.dart';
import 'storage/local_store.dart';

Future<void> bootstrap() async {

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
