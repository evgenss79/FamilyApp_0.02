import 'dart:math';
import 'dart:typed_data';

/// A secure key store that lazily generates and caches a 32‑byte
/// data encryption key. In a production application you should
/// persist this key in a secure store (e.g. Keychain/Keystore)
/// so that encrypted Hive boxes can be reopened across sessions.
class SecureKeyStore {
  static const int _len = 32;
  Uint8List? _dek;

  /// Ensures the data encryption key is generated. If a key has
  /// already been generated it is reused. In a real application
  /// this method would retrieve the key from secure storage or
  /// generate and store it if it doesn't exist.
  Future<void> ensureDek() async {
    if (_dek != null) return;
    final rand = Random.secure();
    final bytes = Uint8List(_len);
    for (var i = 0; i < _len; i++) {
      bytes[i] = rand.nextInt(256);
    }
    _dek = bytes;
  }

  /// Returns the data encryption key as a list of bytes. The key is
  /// lazily generated on first access by [ensureDek].
  Future<List<int>> getDek() async {
    await ensureDek();
    return _dek!;
  }
}
