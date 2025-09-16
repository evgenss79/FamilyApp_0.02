import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A secure key store that lazily generates and caches a 32‑byte
/// data encryption key. This implementation persists the key in
/// platform‑provided secure storage (Keychain on iOS/macOS,
/// Keystore on Android) via `flutter_secure_storage`. Persisting
/// the key ensures that encrypted Hive boxes can be reopened
/// across sessions on the same device.
class SecureKeyStore {
  static const int _len = 32;
  static const String _storageKey = 'familyapp_dek';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Uint8List? _dek;

  /// Ensures the data encryption key is generated and persisted.
  /// On first call this method attempts to read the stored key from
  /// secure storage. If no key exists, it generates a new random
  /// 32‑byte key, stores it in secure storage encoded as base64
  /// and caches it in memory. Subsequent calls reuse the cached key.
  Future<void> ensureDek() async {
    if (_dek != null) return;
    // Attempt to read an existing key from secure storage
    final stored = await _storage.read(key: _storageKey);
    if (stored != null) {
      final decoded = base64Decode(stored);
      _dek = Uint8List.fromList(decoded);
      return;
    }
    // Generate a new random key
    final rand = Random.secure();
    final bytes = Uint8List(_len);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    _dek = bytes;
    // Persist the key encoded as base64
    final encoded = base64Encode(bytes);
    await _storage.write(key: _storageKey, value: encoded);
  }

  /// Returns the data encryption key as a list of bytes. The key
  /// will be generated and persisted on first access.
  Future<List<int>> getDek() async {
    await ensureDek();
    return _dek!;
  }
}