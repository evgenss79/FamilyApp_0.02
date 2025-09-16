import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../security/secure_key_store.dart';

/// Initializes Hive with AES encryption using a secure key, then opens all
/// encrypted boxes used by the application.
///
/// The [HiveSecure] class is responsible for bootstrapping Hive and
/// registering encrypted boxes. It ensures that a data encryption key (DEK)
/// is generated via [SecureKeyStore] and used to create an [HiveAesCipher].
///
/// New boxes can be added here when the application introduces new types of
/// persisted data. Each call to [openBox] must supply the same cipher to
/// ensure the contents remain encrypted.
class HiveSecure {
  static Future<void> initEncrypted() async {
    await Hive.initFlutter();
    final store = SecureKeyStore();
    await store.ensureDek();
    final dek = await store.getDek();
    final cipher = HiveAesCipher(dek);
    await Hive.openBox('familyMembersV001', encryptionCipher: cipher);
    await Hive.openBox('tasksV001', encryptionCipher: cipher);
    await Hive.openBox('eventsV001', encryptionCipher: cipher);
    await Hive.openBox('conversationsV001', encryptionCipher: cipher);
    await Hive.openBox('messagesV001', encryptionCipher: cipher);
    // Added box for schedule items. All schedule entries are stored
    // encrypted using the same cipher as other boxes.
    await Hive.openBox('scheduleItemsV001', encryptionCipher: cipher);
  }
}