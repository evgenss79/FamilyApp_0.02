plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
  id("dev.flutter.flutter-gradle-plugin")
  id("com.google.gms.google-services")
}

android {
  namespace = "com.example.family_app"
  compileSdk = 34

  defaultConfig {
    applicationId = "com.example.family_app"
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

  sourceSets["main"].manifest.srcFile("src/main/AndroidManifest.xml")
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
