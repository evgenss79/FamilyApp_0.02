plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // ANDROID-ONLY FIX: Enable Google services plugin required for Android Firebase integration.
    id("com.google.gms.google-services")
    // ANDROID-ONLY FIX: Apply Crashlytics plugin for Android crash reporting.
    id("com.google.firebase.crashlytics")
}

android {
    // ANDROID-ONLY FIX: Align namespace with the Android-only applicationId.
    namespace = "com.familyapp.android"
    // ANDROID-ONLY FIX: Target the mandated Android API level.
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ANDROID-ONLY FIX: Use Java 8 compatibility for Android builds.
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        // ANDROID-ONLY FIX: Ensure Kotlin bytecode targets JVM 1.8 for Android.
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        // ANDROID-ONLY FIX: Application ID matches Firebase configuration for Android-only build.
        applicationId = "com.familyapp.android"
        // ANDROID-ONLY FIX: Enforce Android-only minimum and target SDK versions.
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // ANDROID-ONLY FIX: Enable multidex support required by expanded Android dependencies.
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so 'flutter run --release' works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources {
            // ANDROID-ONLY FIX: Resolve WebRTC shared library conflicts in Android packaging.
            pickFirst("lib/**/libjingle_peerconnection_so.so")
        }
    }

    flutter {
        source = "../.."
    }
}

dependencies {
    // ANDROID-ONLY FIX: Add multidex support for the Android-only application.
    implementation("androidx.multidex:multidex:2.0.1")
}
