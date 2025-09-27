# ANDROID-ONLY FIX: keep Firebase Analytics + Crashlytics models for release builds.
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.remoteconfig.** { *; }

# ANDROID-ONLY FIX: prevent stripping of Flutter plugins that expose native APIs.
-keep class io.flutter.plugins.firebase.crashlytics.** { *; }
-keep class io.flutter.plugins.firebase.core.** { *; }
-keep class io.flutter.plugins.firebase.analytics.** { *; }
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# ANDROID-ONLY FIX: ensure WebRTC peer connection classes remain for runtime reflection.
-keep class org.webrtc.** { *; }

# Preserve annotations for Firebase serialization.
-keepattributes *Annotation*
