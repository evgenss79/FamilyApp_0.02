import 'dart:convert';

/// Utility class for encrypting and decrypting data.
///
/// In this simple implementation the provided `key` is not actually
/// used for the encoding/decoding process. We accept a `List<int>` key
/// for compatibility with callers that retrieve a list of bytes from
/// storage. Both methods simply convert between plain text and its
/// Base64 representation.
class EncryptionUtils {
  /// Encodes a plain string to Base64.
  ///
  /// [plain] is the clear-text string to encode. [key] is ignored in
  /// this implementation but retained for API compatibility.
  static String encryptToBase64(String plain, List<int> key) {
    return base64Encode(utf8.encode(plain));
  }

  /// Decodes a Base64-encoded string back to plain text.
  ///
  /// [cipher] is the Base64-encoded string to decode. [key] is ignored
  /// in this implementation but retained for API compatibility.
  static String decryptFromBase64(String cipher, List<int> key) {
    return utf8.decode(base64Decode(cipher));
  }
}
