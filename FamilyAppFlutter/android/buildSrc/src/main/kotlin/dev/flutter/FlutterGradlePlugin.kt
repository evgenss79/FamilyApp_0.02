package dev.flutter

import org.gradle.api.Plugin
import org.gradle.api.Project

/**
 * Minimal stub of the Flutter Gradle plugin that keeps the Android module buildable
 * when the Flutter SDK is not available in the environment.
 */
class FlutterGradlePlugin : Plugin<Project> {
    override fun apply(target: Project) {
        target.logger.lifecycle("Applying stub Flutter Gradle plugin for Android-only builds")

        target.plugins.withId("com.android.application") {
            target.extensions.extraProperties.set("flutterEmbeddingVersion", "stub")
        }
    }
}
