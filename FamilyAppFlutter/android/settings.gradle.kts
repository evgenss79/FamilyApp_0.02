import java.io.File
import java.util.Properties

fun resolveFlutterSdkPath(): String? {
    System.getenv("FLUTTER_SDK")?.takeIf { it.isNotBlank() }?.let { return it }

    val localPropertiesFile = File(rootDir, "local.properties")
    if (!localPropertiesFile.exists()) {
        return null
    }

    return Properties().let { props ->
        localPropertiesFile.inputStream().use { props.load(it) }
        props.getProperty("flutter.sdk")
    }
}

val flutterSdkPath: String? = resolveFlutterSdkPath()
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    flutterSdkPath?.let { sdkPath ->
        includeBuild("$sdkPath/packages/flutter_tools/gradle")
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        flutterSdkPath?.let { sdkPath ->
            maven { url = uri("$sdkPath/bin/cache/artifacts/engine/android") }
        }
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "FamilyAppFlutter"
include(":app")
