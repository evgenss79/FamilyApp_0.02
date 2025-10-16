#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
WRAPPER_JAR="${ROOT_DIR}/FamilyAppFlutter/android/gradle/wrapper/gradle-wrapper.jar"
PROPS="${ROOT_DIR}/FamilyAppFlutter/android/gradle/wrapper/gradle-wrapper.properties"

if [ -f "$WRAPPER_JAR" ]; then
  exit 0
fi

DIST_URL=$(grep -E '^distributionUrl=' "$PROPS" | sed 's#^distributionUrl=##' | sed 's#\\:#:#g')
GRADLE_VER=$(echo "$DIST_URL" | sed -n 's#.*gradle-\([0-9.]*\).*#\1#p')
[ -n "$GRADLE_VER" ] || { echo "Cannot parse Gradle version from $PROPS" >&2; exit 1; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
zip_file="$tmpdir/gradle-${GRADLE_VER}.zip"

echo "Downloading Gradle distribution: $DIST_URL"
curl -fsSL "$DIST_URL" -o "$zip_file"

shared_jar_path="gradle-${GRADLE_VER}/lib/gradle-wrapper-shared-${GRADLE_VER}.jar"
main_jar_path="gradle-${GRADLE_VER}/lib/plugins/gradle-wrapper-main-${GRADLE_VER}.jar"

unzip -q "$zip_file" "$shared_jar_path" "$main_jar_path" -d "$tmpdir"

mkdir -p "$(dirname "$WRAPPER_JAR")"
extract_dir="$tmpdir/extracted"
mkdir "$extract_dir"

( cd "$extract_dir" && jar xf "$tmpdir/$shared_jar_path" )
( cd "$extract_dir" && jar xf "$tmpdir/$main_jar_path" )

if [ -f "$extract_dir/gradle-wrapper.jar" ]; then
  mv "$extract_dir/gradle-wrapper.jar" "$WRAPPER_JAR"
else
  ( cd "$extract_dir" && jar cf "$WRAPPER_JAR" . )
fi

echo "Saved: $WRAPPER_JAR"
