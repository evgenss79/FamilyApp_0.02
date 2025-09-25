import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../security/secure_key_service.dart';

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
    // ANDROID-ONLY FIX: use the shared secure key for encrypted Hive boxes.
    // SECURITY: all local boxes are encrypted with the derived AES cipher.
    final List<int> keyBytes = await SecureKeyService.getKeyBytes();
    _cipher = HiveAesCipher(keyBytes);
    final HiveAesCipher cipher = _cipher!;
    _boxes['settings'] = await Hive.openBox<Object?>(
      'settings',
      encryptionCipher: cipher,
    );
    _initialized = true;
  }

  static Box<Object?> get settingsBox {
    final Box<dynamic>? box = _boxes['settings'];
    if (box is Box<Object?>) {
      return box;
    }
    throw StateError('LocalStore.init() must be called before accessing boxes');
  }

  static Future<Box<T>> openBox<T>(String name) async {
    if (!_initialized) {
      throw StateError('LocalStore.init() must be called before opening boxes');
    }
    final Box<dynamic>? cached = _boxes[name];
    if (cached is Box<T>) {
      return cached;
    }
    final HiveAesCipher? cipher = _cipher;
    if (cipher == null) {
      throw StateError('Encryption cipher not available');
    }
    final Box<T> box = await Hive.openBox<T>(
      name,
      encryptionCipher: cipher,
    );
    _boxes[name] = box;
    return box;
  }

  static Future<void> saveFcmToken(String token) async {
    await settingsBox.put('fcmToken', token);
  }
}
