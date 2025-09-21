import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class HiveSecure {
  static const _boxName = 'secure';
  static const _dekKey = 'dek_b64';

  /// Создаёт DEK, если отсутствует
  static Future<void> ensureDek() async {
    final box = await Hive.openBox(_boxName);
    if (!box.containsKey(_dekKey)) {
      final newKey = _generateKey();
      final b64 = base64Encode(newKey);
      await box.put(_dekKey, b64);
    }
  }

  /// Возвращает ключ (List<int>)
  static Future<List<int>> getDek() async {
    final box = await Hive.openBox(_boxName);
    final b64 = box.get(_dekKey) as String?;
    if (b64 == null) {
      await ensureDek();
      return await getDek();
    }
    return base64Decode(b64);
  }

  static List<int> _generateKey() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final bytes = utf8.encode('$now-${now * 31}');
    final out = List<int>.filled(32, 0);
    for (var i = 0; i < out.length; i++) {
      out[i] = i < bytes.length ? bytes[i] : (i * 97) & 0xFF;
    }
    return out;
  }
}
