import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptionUtils {
  final Xchacha20 _cipher = Xchacha20.poly1305Aead();

  Future<Map<String, String>> encryptString({
    required String plaintext,
    required List<int> dek,
    Map<String, String>? aad,
  }) async {
    final nonce = await _cipher.newNonce();
    final secretKey = SecretKey(dek);
    final associatedData = aad == null ? null : utf8.encode(jsonEncode(aad));
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
      associatedData: associatedData,
    );
    return {
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(secretBox.cipherText),
      'tag': base64Encode(secretBox.mac.bytes),
    };
  }

  Future<String> decryptString({
    required String nonceB64,
    required String cipherB64,
    required String tagB64,
    required List<int> dek,
    Map<String, String>? aad,
  }) async {
    final secretKey = SecretKey(dek);
    final mac = Mac(base64Decode(tagB64));
    final secretBox = SecretBox(base64Decode(cipherB64),
        nonce: base64Decode(nonceB64), mac: mac);
    final associatedData = aad == null ? null : utf8.encode(jsonEncode(aad));
    final clear = await _cipher.decrypt(
      secretBox,
      secretKey: secretKey,
      associatedData: associatedData,
    );
    return utf8.decode(clear);
  }

  Map<String, dynamic> encryptPiiMapTemplate({
    required Map<String, dynamic> data,
    required Map<String, Map<String, String>> encryptedFields,
  }) {
    return <String, dynamic>{}
      ..addAll(data)
      ..addAll(encryptedFields);
  }
}
