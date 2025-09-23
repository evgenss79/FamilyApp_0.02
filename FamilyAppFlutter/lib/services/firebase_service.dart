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

    final Settings currentSettings = firestore.settings;
    final Settings updatedSettings = currentSettings.copyWith(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    try {
      firestore.settings = updatedSettings;
    } on FirebaseException {
      // Some platforms (e.g. certain web browsers) may not support persistence
      // or might already have it configured. Swallowing the exception keeps
      // initialization resilient while still enabling persistence elsewhere.
    }

    _initialized = true;
  }

  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
