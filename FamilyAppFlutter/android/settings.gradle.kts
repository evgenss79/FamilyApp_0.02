val localPropertiesFile = file("local.properties")
val localProps = java.util.Properties()
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProps.load(it) }
}
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    val flutterSdkPath = localProps.getProperty("flutter.sdk")
    if (flutterSdkPath != null) {
        includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        val flutterSdkPath = localProps.getProperty("flutter.sdk")
        if (flutterSdkPath != null) {
            maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine/android") }
        }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "FamilyAppFlutter"
include(":app")
