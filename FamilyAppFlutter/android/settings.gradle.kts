// FamilyAppFlutter/android/settings.gradle.kts

pluginManagement {
    repositories {
        // Local plugin shelf: allows offline Gradle builds when jars are present in android/gradle/plugins.
        flatDir {
            dirs = setOf(file("gradle/plugins"))
        }
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
    plugins {
        id("com.android.application") version "8.9.1"
        id("org.jetbrains.kotlin.android") version "1.9.24"
        // The Flutter Gradle plugin version is provided by the Flutter SDK.
    }
    resolutionStrategy {
        eachPlugin {
            when (requested.id.id) {
                "org.jetbrains.kotlin.android" ->
                    useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
                "com.android.application" ->
                    useModule("com.android.tools.build:gradle:8.9.1")
                "com.google.gms.google-services" ->
                    useModule("com.google.gms:google-services:4.4.2")
            }
        }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        flatDir {
            dirs = setOf(file("gradle/plugins"))
        }
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "android"
include(":app")
