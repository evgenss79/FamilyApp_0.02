import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

/// Initializes Firebase gracefully. Returns true if initialization succeeded.
class FirebaseBoot {
  static Future<bool> init() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }
}
