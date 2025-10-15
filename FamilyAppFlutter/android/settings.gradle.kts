import java.util.Properties
import java.io.File

rootProject.name = "android"

// ---- Resolve flutterSdkPath from env or local.properties
val localProps = Properties().apply {
    val f = File(rootDir, "local.properties")
    if (f.exists()) f.reader().use { load(it) }
}
val flutterSdkPath: String? =
    System.getenv("FLUTTER_SDK")
        ?: localProps.getProperty("flutter.sdk")

require(!flutterSdkPath.isNullOrBlank()) {
    "Flutter SDK path is not set. Define FLUTTER_SDK env var or flutter.sdk in android/local.properties"
}

// ---- Repositories for plugin & dependency resolution live in SETTINGS (not in project build.gradle)
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter artifacts (embeddings, etc.)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

plugins {
    // Loads Flutter’s Gradle integration
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

include(":app")
