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
