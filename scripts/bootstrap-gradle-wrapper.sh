#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
WRAPPER_JAR="${ROOT_DIR}/FamilyAppFlutter/android/gradle/wrapper/gradle-wrapper.jar"
PROPS="${ROOT_DIR}/FamilyAppFlutter/android/gradle/wrapper/gradle-wrapper.properties"

if [ ! -f "$PROPS" ]; then
  echo "Missing Gradle wrapper properties at $PROPS" >&2
  exit 1
fi

DIST_URL=$(grep -E '^distributionUrl=' "$PROPS" | sed 's#^distributionUrl=##' | sed 's#\\:#:#g')
ZIP_NAME=$(basename "$DIST_URL")
DIST_NAME=${ZIP_NAME%.zip}
CORE_VERSION=${DIST_NAME#gradle-}
if [[ $CORE_VERSION == *-all ]]; then
  CORE_VERSION=${CORE_VERSION%-all}
elif [[ $CORE_VERSION == *-bin ]]; then
  CORE_VERSION=${CORE_VERSION%-bin}
fi
GRADLE_DIR="gradle-${CORE_VERSION}"
GRADLE_VERSION="$CORE_VERSION"
GRADLE_USER_HOME=${GRADLE_USER_HOME:-"$HOME/.gradle"}
BASE36_HASH=$(python3 - "$DIST_URL" <<'PY'
import hashlib, sys
url = sys.argv[1]
value = int(hashlib.md5(url.encode()).hexdigest(), 16)
digits = '0123456789abcdefghijklmnopqrstuvwxyz'
if value == 0:
    print('0')
else:
    out = []
    while value:
        value, rem = divmod(value, 36)
        out.append(digits[rem])
    print(''.join(reversed(out)))
PY
)
DIST_DIR="$GRADLE_USER_HOME/wrapper/dists/$DIST_NAME/$BASE36_HASH"
ZIP_TARGET="$DIST_DIR/$ZIP_NAME"
EXTRACT_DIR="$DIST_DIR/$GRADLE_DIR"

if [[ ! -f "$ZIP_TARGET" ]]; then
  mkdir -p "$DIST_DIR"
  echo "Downloading Gradle distribution: $DIST_URL"
  curl -fsSL "$DIST_URL" -o "$ZIP_TARGET"
fi

if [[ ! -d "$EXTRACT_DIR" ]]; then
  echo "Extracting Gradle distribution to $EXTRACT_DIR"
  unzip -q "$ZIP_TARGET" -d "$DIST_DIR"
fi

if [[ ! -f "$WRAPPER_JAR" ]]; then
  echo "Generating Gradle wrapper jar using local distribution"
  TMP_WRAPPER=$(mktemp -d)
  cat > "$TMP_WRAPPER/settings.gradle" <<'EOF'
rootProject.name = "bootstrap"
EOF
  cat > "$TMP_WRAPPER/build.gradle" <<'EOF'
// empty project for wrapper generation
EOF
  "$EXTRACT_DIR/bin/gradle" -q -p "$TMP_WRAPPER" wrapper --gradle-version "$GRADLE_VERSION" --distribution-type all --gradle-distribution-url "$DIST_URL"
  mkdir -p "$(dirname "$WRAPPER_JAR")"
  cp "$TMP_WRAPPER/gradle/wrapper/gradle-wrapper.jar" "$WRAPPER_JAR"
  rm -rf "$TMP_WRAPPER"
fi

# Output the path to the extracted Gradle home for callers that need it
printf '%s' "$EXTRACT_DIR"
