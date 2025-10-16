#!/usr/bin/env bash
# Orchestrates Android builds that work without network access by relying on
# locally provided Gradle plugin jars. The script follows the workflow outlined
# in PROMPT для Codex: detect connectivity, fall back to offline validation when
# jars are missing, and iteratively build the :app:assembleDebug target when the
# dependencies are available.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ANDROID_DIR="$REPO_ROOT/FamilyAppFlutter/android"
PLUGINS_DIR="$ANDROID_DIR/gradle/plugins"
REPORT_FILE="$ANDROID_DIR/offline_validation_report.md"

if [[ ! -d "$ANDROID_DIR" ]]; then
  echo "Android project directory not found: $ANDROID_DIR" >&2
  exit 1
fi

mkdir -p "$PLUGINS_DIR"

cd "$ANDROID_DIR"

OFFLINE=0
HELP_LOG=$(mktemp)
TIMEOUT_CMD=()
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(timeout 120)
fi

set +e
"${TIMEOUT_CMD[@]}" ./gradlew --no-daemon help >"$HELP_LOG" 2>&1
HELP_EXIT=$?
set -e

if [[ $HELP_EXIT -ne 0 ]]; then
  echo "Gradle help command exited with status $HELP_EXIT. Assuming offline mode." >&2
  OFFLINE=1
fi
if grep -Eq "Could not resolve|plugin was not found" "$HELP_LOG"; then
  echo "Gradle reported unresolved dependencies. Switching to offline mode." >&2
  OFFLINE=1
fi

if [[ $OFFLINE -eq 1 ]]; then
  echo "[offline] Network access unavailable or dependency resolution failed." >&2
  shopt -s nullglob
  jars=($PLUGINS_DIR/*.jar)
  shopt -u nullglob
  if (( ${#jars[@]} == 0 )); then
    cat >"$REPORT_FILE" <<'MARKDOWN'
# Android Offline Validation Report

- Gradle network access: unavailable (detected via `gradlew --no-daemon help`).
- Local plugin repository: **missing** required jars in `android/gradle/plugins/`.
- Settings configuration: configured for `flatDir` plugin repositories.
- Action required: copy Kotlin 1.9.24, Android Gradle Plugin 8.9.1, Google Services 4.4.2 (and their dependencies) into `FamilyAppFlutter/android/gradle/plugins/`.

Once the jars are in place, rerun `scripts/android-offline-build.sh` to assemble the debug APK offline.
MARKDOWN
    echo "offline ready; upload required jars to android/gradle/plugins/"
    exit 0
  fi
else
  echo "[online] Gradle help succeeded without missing dependency errors." >&2
fi

echo "Stopping Gradle daemons (if any)…"
./gradlew --stop >/dev/null 2>&1 || true

echo "Cleaning project…"
./gradlew clean

attempt=0
while true; do
  echo "Attempt $((attempt + 1)) to build :app:assembleDebug"
  if ./gradlew :app:assembleDebug -x lint --info; then
    echo "✅ SUCCESS: :app:assembleDebug"
    break
  fi

  attempt=$((attempt + 1))
  BUILD_LOG=$(mktemp)
  echo "Build failed. Collecting diagnostics (log: $BUILD_LOG)…"
  set +e
  ./gradlew :app:assembleDebug -x lint --stacktrace --info >"$BUILD_LOG" 2>&1
  set -e

  if grep -Eq 'Could not find .+\.jar' "$BUILD_LOG" || grep -Eq 'Could not resolve .+:' "$BUILD_LOG"; then
    echo ">> Missing artifact detected. Please add its JAR(s) into android/gradle/plugins/."
    grep -E 'Could not (find|resolve) .+' "$BUILD_LOG" | tail -n 20 || true
    exit 2
  fi

  if grep -q 'Could not find or load main class "-Djava.net.preferIPv4Stack=true"' "$BUILD_LOG"; then
    echo ">> Fixing IPv4 stack JVM option quoting in gradlew."
    sed -i.bak 's/"-Djava.net.preferIPv4Stack=true"/-Djava.net.preferIPv4Stack=true/g' gradlew || true
    sed -i.bak "s/'-Djava.net.preferIPv4Stack=true'/-Djava.net.preferIPv4Stack=true/g" gradlew || true
    chmod +x gradlew
    continue
  fi

  if grep -qi 'No matching client found for package name' "$BUILD_LOG"; then
    echo ">> Google services package mismatch detected. Ensure applicationId/namespace matches google-services.json." >&2
    exit 3
  fi

  if (( attempt >= 6 )); then
    echo "Too many attempts. See the last 200 log lines for details:"
    tail -n 200 "$BUILD_LOG"
    exit 1
  fi

done
