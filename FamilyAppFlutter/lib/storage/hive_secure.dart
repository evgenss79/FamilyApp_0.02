import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class HiveSecure {
  static const _boxName = 'secure';
  static const _dekKey = 'dek_b64';

  /// Гарантирует наличие DEK (32 байта), хранит в base64.
  static Future<void> ensureDek() async {
    final box = await Hive.openBox(_boxName);
    if (!box.containsKey(_dekKey)) {
      final key = _generateKey(32);
      await box.put(_dekKey, base64Encode(key));
    }
  }

  /// Возвращает DEK как List<int>. Если нет — создаёт.
  static Future<List<int>> getDek() async {
    final box = await Hive.openBox(_boxName);
    String? b64 = box.get(_dekKey) as String?;
    if (b64 == null) {
      await ensureDek();
      b64 = box.get(_dekKey) as String?;
    }
    return base64Decode(b64!);
  }

  static List<int> _generateKey(int length) {
    final r = Random.secure();
    return List<int>.generate(length, (_) => r.nextInt(256));
  }
}
