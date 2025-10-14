val localProperties = file("local.properties")
val properties = java.util.Properties()
if (localProperties.exists()) {
    localProperties.inputStream().use { properties.load(it) }
}
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    val flutterSdkPath = properties.getProperty("flutter.sdk")
    if (flutterSdkPath != null) {
        includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        if (flutterSdkPath != null) {
            maven { url = uri("$flutterSdkPath/bin/cache/artifacts/engine/android") }
        }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "FamilyAppFlutter"
include(":app")
