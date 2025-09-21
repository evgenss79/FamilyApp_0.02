import 'dart:convert';
import 'dart:math';

/// Простейшее "хранилище ключей". Для компиляции и локальной работы:
/// - генерирует и хранит в памяти Data Encryption Key (DEK);
/// - методы async, как у реального секьюр-хранилища.
class SecureKeyStore {
  static final Map<String, String> _mem = {};
  static const _dekKey = 'familyapp_dek';

  /// Убедиться, что DEK существует.
  static Future<void> ensureDek() async {
    if (_mem.containsKey(_dekKey)) return;
    _mem[_dekKey] = _randomBase64(32);
  }

  /// Вернуть DEK (base64). Если отсутствует — сгенерировать.
  static Future<String> getDek() async {
    await ensureDek();
    return _mem[_dekKey]!;
  }

  static String _randomBase64(int bytes) {
    final rnd = Random.secure();
    final data = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return base64Encode(data);
  }
}
