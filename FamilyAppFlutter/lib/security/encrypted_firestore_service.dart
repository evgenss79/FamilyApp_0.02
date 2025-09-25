import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pointycastle/export.dart';

import 'secure_key_service.dart';

/// Хранит в поле "enc" JSON-строку с пакетом:
/// { "v":1, "alg":"AES-GCM", "iv":"base64", "ct":"base64" }
/// - iv: 12 байт IV (nonce)
/// - ct: шифртекст + тег (PointyCastle GCM process() возвращает сразу ct||tag)
class EncryptedFirestoreService {
  const EncryptedFirestoreService();

  /// Чтение и расшифровка. Если "enc" отсутствует/битый — вернёт обычные поля.
  Future<Map<String, dynamic>> getDecrypted({
    required DocumentReference<Map<String, dynamic>> ref,
  }) async {
    final snap = await ref.get();
    return decode(snap.data());
  }

  /// Расшифровывает данные из снапшота.
  Future<Map<String, dynamic>> decode(
      Map<String, dynamic>? raw) async {
    if (raw == null) return {};
    final enc = raw['enc'];
    if (enc is String) {
      try {
        final bundle = json.decode(enc);
        if (bundle is Map<String, dynamic>) {
          final ivB64 = bundle['iv'] as String?;
          final ctB64 = bundle['ct'] as String?;
          if (ivB64 != null && ctB64 != null) {
            final iv = base64Decode(ivB64);
            final cipherBytes = base64Decode(ctB64);

            final keyBytes = Uint8List.fromList(await SecureKeyService.getKeyBytes());
            final key = KeyParameter(keyBytes);

            final gcm = GCMBlockCipher(AESEngine());
            final params =
                AEADParameters(key, 128, Uint8List.fromList(iv), Uint8List(0));
            gcm.init(false, params);

            final plainBytes = gcm.process(Uint8List.fromList(cipherBytes));
            final plainStr = utf8.decode(plainBytes);
            final decoded = json.decode(plainStr);
            if (decoded is Map<String, dynamic>) return decoded;
          }
        }
      } catch (_) {
        // если не получилось — отдаём как есть (несовместимые/старые данные)
      }
    }
    return raw;
  }


  /// Шифрует и возвращает Map, пригодный для set/WriteBatch.
  Future<Map<String, dynamic>> encryptPayload(
      Map<String, dynamic> data) async {
    // Гарантируем наличие ключа перед шифрованием.
    await SecureKeyService.ensureKey();

    final keyBytes = Uint8List.fromList(await SecureKeyService.getKeyBytes());
    final key = KeyParameter(keyBytes);

    // SECURITY: используем независимый IV для каждой записи.
    final iv = _randomBytes(12);

    final gcm = GCMBlockCipher(AESEngine());
    final params = AEADParameters(key, 128, iv, Uint8List(0));
    gcm.init(true, params);

    final plain = utf8.encode(json.encode(data));
    final cipher = gcm.process(Uint8List.fromList(plain)); // ct||tag

    final bundle = <String, dynamic>{
      'v': 1,
      'alg': 'AES-GCM',
      'iv': base64Encode(iv),
      'ct': base64Encode(cipher),
    };

    return <String, dynamic>{'enc': json.encode(bundle)};
  }

  /// Шифрует и сохраняет Map в поле "enc".
  Future<void> setEncrypted({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
  }) async {
    final Map<String, dynamic> payload = await encryptPayload(data);
    await ref.set(payload, SetOptions(merge: true));
  }

  Uint8List _randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
  }
}
