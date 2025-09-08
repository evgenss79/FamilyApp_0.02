import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';

class SecureKeyStore {
  static const _dekKey = 'familyapp.dek.v1';
  static const _wrappedDekKey = 'familyapp.wrapped_dek.v1';
  static const _saltKey = 'familyapp.kdf.salt.v1';
  static const _kekVersionKey = 'familyapp.kek.version';

  final FlutterSecureStorage _storage;
  final Pbkdf2 _pbkdf2;

  SecureKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _pbkdf2 = Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: 150000,
          bits: 256,
        );

  Future<Uint8List> _generateKey32() async {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  Future<void> ensureDek() async {
    final dek = await _storage.read(key: _dekKey);
    if (dek == null) {
      final newDek = await _generateKey32();
      await _storage.write(key: _dekKey, value: base64Encode(newDek));
    }
    final salt = await _storage.read(key: _saltKey);
    if (salt == null) {
      final s = await _generateKey32();
      await _storage.write(key: _saltKey, value: base64Encode(s));
    }
  }

  Future<Uint8List> getDek() async {
    final val = await _storage.read(key: _dekKey);
    if (val == null) {
      throw StateError('DEK not initialized');
    }
    return base64Decode(val);
  }

  Future<SecretKey> deriveKekFromPassphrase(String passphrase) async {
    final saltB64 = await _storage.read(key: _saltKey);
    if (saltB64 == null) {
      throw StateError('Salt not initialized');
    }
    final salt = base64Decode(saltB64);
    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
    await _storage.write(key: _kekVersionKey, value: 'pbkdf2.v1');
    return secretKey;
  }

  Future<Map<String, String>> wrapDek(SecretKey kek) async {
    final cipher = Xchacha20.poly1305Aead();
    final nonce = await cipher.newNonce();
    final dek = await getDek();
    final box = await cipher.encrypt(dek, secretKey: kek, nonce: nonce);
    final wrapped = base64Encode(box.cipherText);
    final tag = base64Encode(box.mac.bytes);
    final nonceB64 = base64Encode(nonce);
    return {'nonce': nonceB64, 'cipher': wrapped, 'tag': tag};
  }

  Future<void> unwrapDek(
    SecretKey kek, {
    required String nonceB64,
    required String cipherB64,
    required String tagB64,
  }) async {
    final cipher = Xchacha20.poly1305Aead();
    final nonce = base64Decode(nonceB64);
    final mac = Mac(base64Decode(tagB64));
    final secretBox = SecretBox(base64Decode(cipherB64), nonce: nonce, mac: mac);
    final dek = await cipher.decrypt(secretBox, secretKey: kek);
    if (dek.length != 32) {
      throw StateError('Invalid DEK length');
    }
    await _storage.write(key: _dekKey, value: base64Encode(dek));
  }

  Future<void> saveWrappedDek(Map<String, String> wrapped) async {
    await _storage.write(key: _wrappedDekKey, value: jsonEncode(wrapped));
  }

  Future<Map<String, String>?> readWrappedDek() async {
    final val = await _storage.read(key: _wrappedDekKey);
    if (val == null) return null;
    return Map<String, String>.from(jsonDecode(val));
  }

  Future<Uint8List> rotateDek() async {
    final oldDek = await getDek();
    final newDek = await _generateKey32();
    await _storage.write(key: _dekKey, value: base64Encode(newDek));
    return oldDek;
  }
}
