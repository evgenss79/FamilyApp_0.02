// FamilyAppFlutter/android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // очень важно: Flutter gradle plugin
    id("dev.flutter.flutter-gradle-plugin")
    // Google services (ниже мы синхронизируем applicationId)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.family_app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.family_app"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.annotation:annotation:1.8.1")
}

tasks.register("lint") {
    group = "verification"
    description = "Stub lint task for offline builds"
    doLast { logger.lifecycle("Lint skipped (stub task)") }
}
