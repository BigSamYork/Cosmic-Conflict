#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${VERSION:?Set VERSION to the release version}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid VERSION: $VERSION" >&2; exit 1; }
editor="$PWD/.tools/mac/Godot.app/Contents/MacOS/Godot"
out="$PWD/releases/$VERSION"
stage=$(mktemp -d)
cp current_dev/project.godot "$stage/project.godot"
project_settings="$PWD/current_dev/project.godot"
trap 'cp "$stage/project.godot" "$project_settings"; rm -r "$stage"' EXIT
mkdir -p "$out" "$stage/package"
sed -E "s/^config\\/version=.*/config\\/version=\"$VERSION\"/" "$stage/project.godot" > current_dev/project.godot
grep -Fxq "config/version=\"$VERSION\"" current_dev/project.godot
app="$stage/package/Cosmic Conflict.app"
"$editor" --headless --path current_dev --editor --import --quit
"$editor" --headless --path current_dev --export-release macOS "$app"
plist="$app/Contents/Info.plist"
exe="$app/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")" == "$VERSION" ]]
lipo -verify_arch x86_64 arm64 "$exe"
codesign --verify --deep --strict "$app"
cd "$stage/package"
"$exe" --headless --audio-driver Dummy --quit-after 10 > "$stage/smoke.log" 2>&1 || { cat "$stage/smoke.log"; exit 1; }
cat "$stage/smoke.log"
if grep -Eq 'SCRIPT ERROR:|^ERROR:' "$stage/smoke.log"; then exit 1; fi
cd - >/dev/null
manual_version=$(jq -er .game_version tools/toolchain.json)
cp Docs/FLIGHT_LAB.md Docs/LICENSES.txt "Docs/Cosmic_Conflict_Player_Manual_v${manual_version}.docx" "$stage/package/"
ditto -c -k --sequesterRsrc "$stage/package" "$out/CosmicConflict-$VERSION-macOS-universal.zip"
