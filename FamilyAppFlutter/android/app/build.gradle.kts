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
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    // Путь к корню Flutter-проекта
    source = "../.."
}

dependencies {
    // если понадобится — явная аннотация (на случай «package androidx.annotation does not exist»)
    implementation("androidx.annotation:annotation:1.8.1")

    // core desugaring (требуется при включенном isCoreLibraryDesugaringEnabled)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
