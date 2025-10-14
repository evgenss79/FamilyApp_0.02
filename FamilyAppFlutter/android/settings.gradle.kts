pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    val properties = java.util.Properties()
    val localProperties = file("local.properties")
    if (localProperties.exists()) {
        localProperties.inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        if (flutterSdkPath != null) {
            includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
        }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "FamilyAppFlutter"
include(":app")
