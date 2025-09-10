import 'dart:convert';

class EncryptionUtils {
  static String encryptToBase64(String plain, String key) {
    // Временная реализация: просто кодирование в base64
    return base64Encode(utf8.encode(plain));
  }

  static String decryptFromBase64(String cipher, String key) {
    return utf8.decode(base64Decode(cipher));
  }
}
