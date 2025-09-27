// lib/core/firebase_boot.dart
import 'package:firebase_core/firebase_core.dart';

class FirebaseBoot {
  static FirebaseApp? _cached;

  static Future<FirebaseApp> ensureInitialized() async {
    if (_cached != null) return _cached!;
    if (Firebase.apps.isNotEmpty) {
      _cached = Firebase.apps.first;
      return _cached!;
    }
    try {
      _cached = await Firebase.initializeApp(); // Android возьмёт конфиг из google-services.json
      return _cached!;
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        _cached = Firebase.app();
        return _cached!;
      }
      rethrow;
    }
  }
}
