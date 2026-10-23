#!/bin/sh
# Render scripts/icon.swift and rebuild support/icon.png (the Dock icon built into the binary)
# and support/AppIcon.icns (the bundle icon) from it.
set -eu
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
swift scripts/icon.swift "$TMP/icon.png"
mkdir "$TMP/AppIcon.iconset"
for s in 16 32 128 256 512; do
  sips -z $s $s "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s * 2)) $((s * 2)) "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$TMP/AppIcon.iconset" -o support/AppIcon.icns
sips -z 1024 1024 "$TMP/icon.png" --out support/icon.png >/dev/null
echo "wrote support/icon.png and support/AppIcon.icns"
