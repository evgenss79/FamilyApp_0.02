/// Stores and retrieves keys securely.  The implementation here is
/// intentionally minimal and does not persist data.  Methods are
/// asynchronous to match typical secure storage APIs.
class SecureKeyStore {
  static final Map<String, String> _store = {};

  /// Saves a key-value pair.  In this stub implementation the data
  /// lives only in memory and is lost on application restart.
  static Future<void> saveKey(String key, String value) async {
    _store[key] = value;
  }

  /// Retrieves a value for the given key, or null if not found.
  static Future<String?> getKey(String key) async {
    return _store[key];
  }
}