import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Centralized Firebase bootstrapper that configures Firestore with offline
/// persistence and exposes the singleton [FirebaseFirestore] instance.
class FirebaseService {
  FirebaseService._();

  static final FirebaseService _instance = FirebaseService._();

  factory FirebaseService() => _instance;

  bool _initialized = false;

  /// Initializes Firebase and enables Firestore persistence.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    _initialized = true;
  }

  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
