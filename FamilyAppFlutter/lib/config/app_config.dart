/// Central place for string constants shared across services.
class AppConfig {
  const AppConfig._();

  static const String usersCollection = 'users';

  static const String remoteConfigAiSuggestionsKey = 'feature_ai_suggestions';
  static const String remoteConfigWebRtcKey = 'feature_webrtc_enabled';
  static const String remoteConfigOnboardingKey = 'feature_onboarding_tips';
}
