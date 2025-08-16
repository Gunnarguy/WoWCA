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
#!/usr/bin/env bash
set -euo pipefail
PROJECT_FILE="WoWCA.xcodeproj/project.pbxproj"
if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Project file not found" >&2
  exit 1
fi
new_marketing=""
if [[ $# -gt 0 ]]; then
  new_marketing="$1"
fi
current_build=$(grep -Eo 'CURRENT_PROJECT_VERSION = [0-9]+' "$PROJECT_FILE" | head -1 | awk '{print $3}')
next_build=$((current_build + 1))
echo "Current build: $current_build -> $next_build"
sed -i '' -E "s/CURRENT_PROJECT_VERSION = ${current_build};/CURRENT_PROJECT_VERSION = ${next_build};/g" "$PROJECT_FILE"
if [[ -n "$new_marketing" ]]; then
  echo "Setting MARKETING_VERSION to $new_marketing"
  sed -i '' -E "s/MARKETING_VERSION = [0-9A-Za-z.-]+;/MARKETING_VERSION = ${new_marketing};/g" "$PROJECT_FILE"
fi
echo "Done. Remember to git commit the change." 
