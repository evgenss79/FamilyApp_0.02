import 'dart:async';


import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Crashlytics wiring for the Android-only build.
class CrashlyticsService {
  CrashlyticsService._();

  /// Singleton accessor for the Crashlytics service.
  static final CrashlyticsService instance = CrashlyticsService._();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // ANDROID-ONLY FIX: funnel Flutter framework exceptions into Crashlytics.
      _crashlytics.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      // ANDROID-ONLY FIX: capture async Android errors for Crashlytics dashboards.
      _crashlytics.recordError(error, stackTrace, fatal: true);
      return false;
    };
    _initialized = true;
  }

  Future<void> recordNonFatal(Object error, StackTrace stackTrace) async {
    await _crashlytics.recordError(error, stackTrace, fatal: false);
  }

  Future<void> recordFatal(Object error, StackTrace stackTrace) async {
    await _crashlytics.recordError(error, stackTrace, fatal: true);
  }

  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> setUserContext({
    required String memberId,
    String? familyId,
    String? email,
  }) async {
    await _crashlytics.setUserIdentifier(memberId);
    if (familyId != null) {
      await _crashlytics.setCustomKey('family_id', familyId);
    }
    if (email != null && email.isNotEmpty) {
      await _crashlytics.setCustomKey('member_email', email);
    }
  }

  Future<void> clearUserContext() async {
    await _crashlytics.setUserIdentifier('');
    await _crashlytics.setCustomKey('family_id', '');
    await _crashlytics.setCustomKey('member_email', '');
  }

  Future<void> triggerTestCrash() async {
    await _crashlytics.log('Manual test crash triggered');
    await _crashlytics.setCustomKey(
      'test_crash_timestamp',
      DateTime.now().toIso8601String(),
    );
    _crashlytics.crash();
  }
}
