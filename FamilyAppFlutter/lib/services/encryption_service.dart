import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'secure_storage_service.dart';

/// Represents encrypted payload stored in Firestore.
class EncryptedBlob {
  const EncryptedBlob({
    required this.ciphertext,
    required this.iv,
    required this.version,
  });

  final Uint8List ciphertext;
  final Uint8List iv;
  final int version;

  Map<String, dynamic> toFirestoreMap() => <String, dynamic>{
        'ciphertext': base64Encode(ciphertext),
        'iv': base64Encode(iv),
        'encVersion': version,
      };

  static EncryptedBlob? fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final String? ciphertext = data['ciphertext'] as String?;
    final String? iv = data['iv'] as String?;
    final Object? version = data['encVersion'];
    if (ciphertext == null || iv == null || version == null) {
      return null;
    }
    return EncryptedBlob(
      ciphertext: Uint8List.fromList(base64Decode(ciphertext)),
      iv: Uint8List.fromList(base64Decode(iv)),
      version: version is int ? version : int.tryParse('$version') ?? 0,
    );
  }
}

/// AES-256-GCM implementation used to encrypt/decrypt Firestore documents.
class EncryptionService {
  EncryptionService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  static const int _encVersion = 1;

  final SecureStorageService _secureStorage;
  final Cipher _cipher = AesGcm.with256bits();
  Uint8List? _key;

  Future<void> ensureKey() async {
    if (_key != null) {
      return;
    }
    final Uint8List? storedKey = await _secureStorage.readKey();
    if (storedKey != null && storedKey.length == 32) {
      _key = storedKey;
      return;
    }
    final Uint8List generated = _randomBytes(32);
    await _secureStorage.writeKey(generated);
    _key = generated;
  }

  Future<EncryptedBlob> encrypt(Map<String, dynamic> open) async {
    await ensureKey();
    final Uint8List nonce = _randomBytes(12);
    final SecretBox secretBox = await _cipher.encrypt(
      utf8.encode(jsonEncode(open)),
      secretKey: SecretKey(_key!),
      nonce: nonce,
    );
    final Uint8List combined = Uint8List(
      secretBox.cipherText.length + secretBox.mac.bytes.length,
    )
      ..setRange(0, secretBox.cipherText.length, secretBox.cipherText)
      ..setRange(
        secretBox.cipherText.length,
        secretBox.cipherText.length + secretBox.mac.bytes.length,
        secretBox.mac.bytes,
      );
    return EncryptedBlob(ciphertext: combined, iv: nonce, version: _encVersion);
  }

  Future<Map<String, dynamic>> decrypt(EncryptedBlob blob) async {
    await ensureKey();
    if (blob.version != _encVersion) {
      throw UnsupportedError('Unsupported encryption version ${blob.version}');
    }
    final int macLength = _cipher.macAlgorithm.macLength;
    if (blob.ciphertext.length < macLength) {
      throw const FormatException('Ciphertext shorter than authentication tag');
    }
    final Uint8List cipherText =
        blob.ciphertext.sublist(0, blob.ciphertext.length - macLength);
    final Uint8List macBytes =
        blob.ciphertext.sublist(blob.ciphertext.length - macLength);
    final SecretBox secretBox = SecretBox(
      cipherText,
      nonce: blob.iv,
      mac: Mac(macBytes),
    );
    try {
      final List<int> plainBytes = await _cipher.decrypt(
        secretBox,
        secretKey: SecretKey(_key!),
      );
      final dynamic decoded = jsonDecode(utf8.decode(plainBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('Decrypted payload is not a map');
    } on SecretBoxAuthenticationError catch (error) {
      throw StateError('Unable to decrypt payload: $error');
    }
  }

  Uint8List _randomBytes(int length) {
    final Random random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
