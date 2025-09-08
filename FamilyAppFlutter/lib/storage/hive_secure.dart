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
    await Hive.openBox('family_members_v001', encryptionCipher: cipher);
    await Hive.openBox('tasks_v001', encryptionCipher: cipher);
    await Hive.openBox('events_v001', encryptionCipher: cipher);
    await Hive.openBox('conversations_v001', encryptionCipher: cipher);
    await Hive.openBox('messages_v001', encryptionCipher: cipher);
  }
}
