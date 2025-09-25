import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles creation and retrieval of the AES encryption key that protects
/// all Hive boxes. The key is generated once and persisted via the Android
/// Keystore-backed secure storage so it never touches the filesystem.
class SecureKeyService {
  SecureKeyService._();

  static const String _storageKey = 'familyapp.android.hive_dek';
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // ANDROID-ONLY FIX: rely on the Android Keystore through flutter_secure_storage.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  static List<int>? _cachedKey;

  /// Ensures that an AES-256 key exists in secure storage and returns it.
  static Future<List<int>> ensureKey() async {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    final String? encoded = await _storage.read(
      key: _storageKey,
      aOptions: _androidOptions,
    );
    if (encoded != null) {
      final List<int> existingKey = base64Decode(encoded);
      _cachedKey = existingKey;
      return existingKey;
    }

    final List<int> keyBytes = _generateSecureRandomBytes();
    // SECURITY: persist the randomly generated DEK only inside the Keystore.
    await _storage.write(
      key: _storageKey,
      value: base64Encode(keyBytes),
      aOptions: _androidOptions,
    );
    _cachedKey = keyBytes;
    return keyBytes;
  }

  /// Provides the AES key bytes for encryption-aware components.
  static Future<List<int>> getKeyBytes() async {
    return ensureKey();
  }

  static List<int> _generateSecureRandomBytes() {
    final Random random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }
}
