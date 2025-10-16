// FamilyAppFlutter/android/settings.gradle.kts

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://plugins.gradle.org/m2") }
        // Хранилище Flutter для артефактов и плагина
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
    plugins {
        id("com.android.application") version "8.9.1"
        // Версию Flutter Gradle Plugin оставляем неопределённой — её предоставляет Flutter SDK.
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://plugins.gradle.org/m2") }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "android"
include(":app")
