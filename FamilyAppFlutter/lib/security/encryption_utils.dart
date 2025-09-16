import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Utility class for encrypting and decrypting data using AES.
///
/// This implementation uses AES‑CBC with a random 16‑byte IV and PKCS7 padding.
/// The provided [key] must be 32 bytes (256 bits) long. The IV is generated
/// automatically for each encryption operation and prepended to the ciphertext
/// before Base64 encoding. When decrypting, the IV is extracted from the
/// beginning of the decoded bytes. This design means each call to
/// [encryptToBase64] produces a unique output even for the same input.
class EncryptionUtils {
  /// Encrypts a plain string to a Base64‑encoded string.
  ///
  /// [plain] is the clear‑text string to encrypt. [key] is a 32‑byte list
  /// representing the AES key. A new 16‑byte IV is generated for each call.
  static String encryptToBase64(String plain, List<int> key) {
    // Convert key bytes to encrypt.Key. If the key length is not 32 bytes,
    // this will throw.
    final aesKey = encrypt.Key(Uint8List.fromList(key));
    // Generate a random IV of 16 bytes.
    final iv = encrypt.IV.fromSecureRandom(16);
    // Create an AES encrypter in CBC mode with PKCS7 padding.
    final encrypter =
        encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    // Perform encryption.
    final encrypted = encrypter.encrypt(plain, iv: iv);
    // Combine IV and encrypted bytes. The receiver must know that the first
    // 16 bytes correspond to the IV.
    final combined = <int>[]
      ..addAll(iv.bytes)
      ..addAll(encrypted.bytes);
    // Return Base64 encoding of the combined bytes.
    return base64Encode(combined);
  }

  /// Decrypts a Base64‑encoded string back to plain text.
  ///
  /// [cipher] is the Base64‑encoded string produced by [encryptToBase64].
  /// [key] must be the same 32‑byte list used for encryption.
  static String decryptFromBase64(String cipher, List<int> key) {
    // Decode Base64 to raw bytes. Combined bytes = IV (first 16 bytes) + cipher.
    final combinedBytes = base64Decode(cipher);
    if (combinedBytes.length < 16) {
      throw ArgumentError('Cipher text is too short to contain an IV');
    }
    // Split into IV and ciphertext.
    final ivBytes = combinedBytes.sublist(0, 16);
    final cipherBytes = combinedBytes.sublist(16);
    final aesKey = encrypt.Key(Uint8List.fromList(key));
    final iv = encrypt.IV(ivBytes);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    final encrypted = encrypt.Encrypted(Uint8List.fromList(cipherBytes));
    // Decrypt and return plain string.
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
