#!/usr/bin/env bash
set -euo pipefail

# Simple semantic version bump script for MARKETING_VERSION (CFBundleShortVersionString)
# Usage: ./bump_version.sh [major|minor|patch]

MODE=${1:-patch}
PBXPROJ="WoWCA.xcodeproj/project.pbxproj"

current=$(grep -Eo 'MARKETING_VERSION = [0-9]+\.[0-9]+(\.[0-9]+)?;' "$PBXPROJ" | head -1 | awk '{print $3}' | tr -d ';')
IFS='.' read -r major minor patch <<<"${current}.0.0"
major=${major:-1}; minor=${minor:-0}; patch=${patch:-0}

case "$MODE" in
  major) major=$((major+1)); minor=0; patch=0;;
  minor) minor=$((minor+1)); patch=0;;
  patch) patch=$((patch+1));;
  *) echo "Unknown mode: $MODE" >&2; exit 1;;
esac

newVersion="$major.$minor.$patch"
echo "Bumping MARKETING_VERSION: $current -> $newVersion"
sed -i '' -E "s/MARKETING_VERSION = ${current};/MARKETING_VERSION = ${newVersion};/g" "$PBXPROJ"

# Increment build number (CURRENT_PROJECT_VERSION)
build=$(grep -Eo 'CURRENT_PROJECT_VERSION = [0-9]+' "$PBXPROJ" | head -1 | awk '{print $3}')
newBuild=$((build+1))
sed -i '' -E "s/CURRENT_PROJECT_VERSION = ${build};/CURRENT_PROJECT_VERSION = ${newBuild};/g" "$PBXPROJ"

echo "Build number: $build -> $newBuild"
git add "$PBXPROJ"
echo "Updated version to $newVersion ($newBuild). Remember to commit and tag if desired."
