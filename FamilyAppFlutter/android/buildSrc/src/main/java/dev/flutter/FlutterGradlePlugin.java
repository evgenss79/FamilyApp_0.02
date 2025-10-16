package dev.flutter;

import org.gradle.api.Plugin;
import org.gradle.api.Project;

public class FlutterGradlePlugin implements Plugin<Project> {
    @Override
    public void apply(Project target) {
        target.getLogger().lifecycle("Applying stub Flutter Gradle plugin for Android-only builds");
        target.getExtensions().getExtraProperties().set("flutterEmbeddingVersion", "stub");
    }
}
