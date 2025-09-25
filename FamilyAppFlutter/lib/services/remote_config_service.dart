import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Handles Firebase Remote Config fetching so feature flags can be toggled
/// without shipping a new Android build.
class RemoteConfigService extends ChangeNotifier {
  RemoteConfigService._();

  /// Global singleton because Remote Config values need to be shared across
  /// the entire app lifecycle.
  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _initialized = false;

  bool get isReady => _initialized;

  bool get aiSuggestionsEnabled =>
      _remoteConfig.getBool(AppConfig.remoteConfigAiSuggestionsKey);

  bool get webRtcEnabled =>
      _remoteConfig.getBool(AppConfig.remoteConfigWebRtcKey);

  bool get onboardingTipsEnabled =>
      _remoteConfig.getBool(AppConfig.remoteConfigOnboardingKey);

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    // ANDROID-ONLY FIX: seed Android feature flags before fetching remote values.
    await _remoteConfig.setDefaults(<String, dynamic>{
      AppConfig.remoteConfigAiSuggestionsKey: true,
      AppConfig.remoteConfigWebRtcKey: true,
      AppConfig.remoteConfigOnboardingKey: true,
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Ignore fetch errors; defaults will remain in place so features stay on.
    }

    _initialized = true;
    notifyListeners();
  }
}
