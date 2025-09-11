
import 'dart:convert';

class SecureKeyStore {
  static const _len = 32;

  Future<void> ensureDek() async {
    // В реальном приложении сохраните ключ в надёжном хранилище.
    // Здесь демонстрационный вариант без сохранения.
  }

  /// Возвращает 32-байтный ключ для HiveAesCipher.
  Future<List<int>> getDek() async {
    // Детерминированный "dev key": кодируем строку и дополняем до 32 байт
    final base = utf8.encode('familyapp-insecure-development-key-32bytes');
    if (base.length >= _len) {
      return base.sublist(0, _len);
    }
    final out = List<int>.filled(_len, 0);
    out.setAll(0, base);
    return out;
  }
}
