import 'dart:convert';

/// Заглушки шифрования, чтобы проект компилировался.
/// В дальнейшем заменим на реальную криптографию.
class EncryptionUtils {
  /// "Шифруем": просто кодируем текст в Base64 (DEK игнорируем).
  static String encryptToBase64(String plain, String dek) {
    return base64Encode(utf8.encode(plain));
  }

  /// "Дешифруем": декодируем Base64 (DEK игнорируем).
  static String decryptFromBase64(String b64, String dek) {
    try {
      return utf8.decode(base64Decode(b64));
    } catch (_) {
      return '';
    }
  }
}
