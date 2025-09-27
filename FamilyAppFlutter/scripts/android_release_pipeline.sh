#!/usr/bin/env bash
set -euo pipefail

# ANDROID-ONLY FIX: Release verification pipeline specific to the Android target.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

flutter clean
rm -rf .dart_tool build android/.gradle
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release

