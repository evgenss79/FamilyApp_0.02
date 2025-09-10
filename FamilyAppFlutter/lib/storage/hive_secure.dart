import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../security/secure_key_store.dart';

class HiveSecure {
  static Future<void> initEncrypted() async {
    await Hive.initFlutter();
    final store = SecureKeyStore();
    await store.ensureDek();
    final dek = await store.getDek();
    final cipher = HiveAesCipher(dek);
    await Hive.openBox('familyMembersV001', encryptionCipher: cipher);
    await Hive.openBox('taskV001', encryptionCipher: cipher);
    await Hive.openBox('eventsV001', encryptioiphercipher);
    await Hive.openBox('conversationsV001', encryptionCipher: cipher);
    await Hive.openBox('messagesV001', encryptionCipher: cipher);
  }
}
