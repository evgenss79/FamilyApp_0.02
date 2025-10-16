# Build Notes

- Updated the Android app ID and namespace to `com.example.family_app` to match Firebase.
- Switched the Android toolchains to Java 17 with core library desugaring and Kotlin JVM toolchain configuration.
- Added Gradle settings repositories and Java toolchain path to support standalone Gradle builds.
- Fixed Android manifest and Firebase configuration package names for Google services processing.
- Provisioned the Android SDK locally to satisfy Gradle builds without Flutter tooling.
- Modernised the Android Gradle configuration to use the Flutter Gradle Plugin v2 with centralized repository management.

## Building

1. `flutter pub get`
2. `flutter build apk --debug`
3. (optional for local testing) `flutter run -d emulator-5554`

## Offline Android builds

Run `scripts/android-offline-build.sh` to orchestrate offline-friendly Gradle builds. The script:

1. Probes connectivity with `./gradlew --no-daemon help` and switches to offline mode when resolution fails.
2. Writes `android/offline_validation_report.md` and exits successfully when plugin jars are missing.
3. Iteratively retries `:app:assembleDebug` (skipping lint) once the required jars are placed in `android/gradle/plugins/`.

Place the following artifacts in `FamilyAppFlutter/android/gradle/plugins/` for a full offline build: Kotlin Gradle plugin 1.9.24, Android Gradle Plugin 8.9.1, Google Services plugin 4.4.2, and any transitive jars Gradle requests.
