import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../security/secure_key_service.dart';

/// Centralized entry point for all Hive operations. Guarantees that every box
/// is encrypted with the AES key stored in the Android Keystore and that all
/// adapters are registered prior to usage.
class LocalStore {
  LocalStore._();

  static bool _initialized = false;
  static HiveAesCipher? _cipher;
  static final Map<String, Box<dynamic>> _boxes = <String, Box<dynamic>>{};

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();
    _registerAdapters();

    final List<int> keyBytes = await SecureKeyService.getKeyBytes();
    // ANDROID-ONLY FIX: construct the Hive cipher from the Keystore-backed key.
    // SECURITY: all local data is sealed with the AES cipher derived below.
    _cipher = HiveAesCipher(keyBytes);

    await _openEncryptedBox<Object?>('settings');
    _initialized = true;
  }

  static Box<Object?> get settingsBox {
    final Box<dynamic>? box = _boxes['settings'];
    if (box is Box<Object?>) {
      return box;
    }
    throw StateError('LocalStore.init() must run before accessing Hive boxes');
  }

  static Future<Box<T>> openBox<T>(String name) async {
    if (!_initialized) {
      throw StateError('LocalStore.init() must be called before opening boxes');
    }

    final Box<dynamic>? cached = _boxes[name];
    if (cached is Box<T>) {
      return cached;
    }

    return _openEncryptedBox<T>(name);
  }

  static Future<void> saveFcmToken(String token) async {
    await settingsBox.put('fcmToken', token);
  }

  static String? getFcmToken() {
    // ANDROID-ONLY FIX: expose the Android-registered FCM token for profile syncs.
    final Object? value = settingsBox.get('fcmToken');
    return value is String ? value : null;
  }

  static bool isOnboardingTipsDismissed() {
    final Object? value = settingsBox.get('onboardingTipsDismissed');
    return value is bool ? value : false;
  }

  static Future<void> setOnboardingTipsDismissed(bool dismissed) async {
    // ANDROID-ONLY FIX: persist the Android onboarding banner preference inside the encrypted box.
    await settingsBox.put('onboardingTipsDismissed', dismissed);
  }

  static Future<Box<T>> _openEncryptedBox<T>(String name) async {
    final HiveAesCipher? cipher = _cipher;
    if (cipher == null) {
      throw StateError('Encryption cipher not initialized');
    }

    final Box<T> box = await Hive.openBox<T>(
      name,
      encryptionCipher: cipher,
    );
    _boxes[name] = box;
    return box;
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(ChatAdapter().typeId)) {
      Hive.registerAdapter(ChatAdapter());
    }
    if (!Hive.isAdapterRegistered(MessageTypeAdapter().typeId)) {
      Hive.registerAdapter(MessageTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(ChatMessageAdapter().typeId)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
  }
}
