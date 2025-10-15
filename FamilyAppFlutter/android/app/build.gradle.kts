import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

val flutterStubDir = layout.buildDirectory.dir("generated/flutterStub/src")

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    val appId = "com.familyapp.android"
    namespace = appId

    compileSdk = 34

    defaultConfig {
        applicationId = appId
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        manifestPlaceholders["applicationName"] = "android.app.Application"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    buildFeatures {
        buildConfig = true
    }
    testOptions {
        unitTests.isIncludeAndroidResources = true
    }
    lint {
        disable.add("PermissionImpliesUnsupportedChromeOsHardware")
    }
    sourceSets["main"].java.srcDir(flutterStubDir)
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
    implementation("androidx.activity:activity-ktx:1.9.3")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.12.2")
    testImplementation("androidx.test:core:1.5.0")
    testImplementation("com.google.truth:truth:1.4.2")
    testImplementation("io.mockk:mockk:1.13.12")
}

if (file("$rootDir/app/google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val generateFlutterStub by tasks.registering {
    outputs.dir(flutterStubDir)
    doLast {
        val outputDir = flutterStubDir.get().asFile
        val stubFile = outputDir.resolve("io/flutter/embedding/android/FlutterActivity.kt")
        stubFile.parentFile.mkdirs()
        stubFile.writeText(
            """
            package io.flutter.embedding.android

            import androidx.activity.ComponentActivity

            open class FlutterActivity : ComponentActivity()
            """.trimIndent()
        )
    }
}

tasks.withType<KotlinCompile>().configureEach {
    dependsOn(generateFlutterStub)
}
