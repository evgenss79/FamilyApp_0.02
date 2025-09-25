import '../storage/hive_secure.dart';

class SecureKeyService {
  const SecureKeyService._();

  static Future<void> ensureKey() async {
    // ANDROID-ONLY FIX: temporary bridge before Keystore integration.
    // SECURITY: ensures a single encryption key is materialised once.
    await HiveSecure.ensureDek();
  }

  static Future<List<int>> getKeyBytes() async {
    await ensureKey();
    // SECURITY: expose key bytes only to encryption-aware components.
    return HiveSecure.getDek();
  }
}
