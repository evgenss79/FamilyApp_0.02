package com.android.build.gradle;

import org.gradle.api.JavaVersion;
import org.gradle.api.Plugin;
import org.gradle.api.Project;
import org.gradle.api.tasks.SourceSetContainer;
import org.gradle.api.tasks.compile.JavaCompile;

public class AppPlugin implements Plugin<Project> {
    @Override
    public void apply(Project project) {
        project.getLogger().lifecycle("Applying stub Android application plugin (offline mode)");
        project.getPluginManager().apply("java");

        AndroidApplicationExtension extension = project.getExtensions()
                .create("android", AndroidApplicationExtension.class, project);

        project.getTasks().register("assembleDebug", task -> {
            task.setGroup("build");
            task.setDescription("Stub assembleDebug task");
            task.dependsOn("classes");
            task.doLast(t -> project.getLogger().lifecycle("assembleDebug completed (stub)"));
        });

        project.getTasks().register("assembleRelease", task -> {
            task.setGroup("build");
            task.setDescription("Stub assembleRelease task");
            task.dependsOn("classes");
            task.doLast(t -> project.getLogger().lifecycle("assembleRelease completed (stub)"));
        });

        project.getTasks().register("bundleDebug", task -> task.dependsOn("assembleDebug"));
        project.getTasks().register("bundleRelease", task -> task.dependsOn("assembleRelease"));
        project.getTasks().register("installDebug", task -> task.dependsOn("assembleDebug"));

        project.getTasks().named("build", task -> task.dependsOn("assembleDebug"));

        project.afterEvaluate(p -> {
            CompileOptions options = extension.getCompileOptions();
            JavaVersion source = options.getSourceCompatibility();
            JavaVersion target = options.getTargetCompatibility();
            project.getTasks().withType(JavaCompile.class).configureEach(javaCompile -> {
                if (source != null) {
                    javaCompile.setSourceCompatibility(source.toString());
                }
                if (target != null) {
                    javaCompile.setTargetCompatibility(target.toString());
                }
            });

            SourceSetContainer sourceSets = project.getExtensions().findByType(SourceSetContainer.class);
            if (sourceSets != null) {
                sourceSets.named("main", sourceSet -> {
                    String javaDir = extension.getSourceSets().get("main").getJavaSrcDir();
                    if (javaDir != null) {
                        sourceSet.getJava().setSrcDirs(java.util.Collections.singletonList(javaDir));
                    }
                });
            }
        });
    }
}
