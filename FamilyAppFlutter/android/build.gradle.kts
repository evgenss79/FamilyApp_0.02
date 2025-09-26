buildscript {
    // ANDROID-ONLY FIX: Provide explicit Kotlin and Firebase tooling for the Android-only build.
    extra["kotlin_version"] = "1.9.22"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ANDROID-ONLY FIX: Ensure Kotlin Gradle plugin matches the mandated version.
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${extra["kotlin_version"]}")
        // ANDROID-ONLY FIX: Add Google services plugin for Firebase support on Android.
        classpath("com.google.gms:google-services:4.4.2")
        // ANDROID-ONLY FIX: Enable Firebase Crashlytics Gradle integration for Android builds.
        classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../..//build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
