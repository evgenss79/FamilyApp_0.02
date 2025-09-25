pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    // ANDROID-ONLY FIX: Match Kotlin plugin version with enforced Android-only toolchain.
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
    // ANDROID-ONLY FIX: Use the mandated Google services plugin version for Android builds.
    id("com.google.gms.google-services") version "4.4.2" apply false
    // ANDROID-ONLY FIX: Register Crashlytics plugin for Android-only crash reporting.
    id("com.google.firebase.crashlytics") version "2.9.9" apply false
}

include(":app")
