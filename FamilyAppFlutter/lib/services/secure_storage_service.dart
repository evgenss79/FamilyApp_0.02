import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for keeping encryption keys in platform keystores.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _encKeyName = 'familyapp_e2ee_master_key_v1';

  final FlutterSecureStorage _storage;

  /// Reads the stored encryption key. Returns `null` when no key is stored yet.
  Future<Uint8List?> readKey() async {
    final String? encoded = await _storage.read(key: _encKeyName);
    if (encoded == null) {
      return null;
    }
    return Uint8List.fromList(base64Decode(encoded));
  }

  /// Persists the provided [key] inside the secure storage container.
  Future<void> writeKey(Uint8List key) {
    final String encoded = base64Encode(key);
    return _storage.write(key: _encKeyName, value: encoded);
  }

  /// Clears the stored encryption key (mostly used for debugging/migration).
  Future<void> deleteKey() {
    return _storage.delete(key: _encKeyName);
  }
}
