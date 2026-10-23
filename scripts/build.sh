#!/bin/sh
# Build tape, assemble dist/Tape.app, and code-sign it with a stable identity so
# macOS privacy grants (screen/mic/camera) survive rebuilds.
#
# The build is "Tape Dev" (com.tinomuchenje.tape.dev), apart from the release's
# com.tinomuchenje.tape. macOS ties each privacy grant to the certificate of the
# app that got it. A copy signed with another certificate under the same bundle
# ID sees the grant switched on in System Settings, but it never applies.
set -eu
cd "$(dirname "$0")/.."
PROFILE="${PROFILE:-release}"
# Keep build output outside the repo (worktrees share it).
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$HOME/.cache/tape-target}"
if [ "$PROFILE" = release ]; then cargo build --release; else cargo build; fi
APP=dist/Tape.app
STAGE=dist/.Tape.app.new
BUNDLE_ID=com.tinomuchenje.tape.dev
# Build the bundle beside the old one and swap it in atomically: overwriting a
# running binary in place makes macOS kill an in-progress recording.
rm -rf "$STAGE"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources"
cp support/Info.plist "$STAGE/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$STAGE/Contents/Info.plist"
plutil -replace CFBundleName -string "Tape Dev" "$STAGE/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "Tape Dev" "$STAGE/Contents/Info.plist"
cp support/AppIcon.icns "$STAGE/Contents/Resources/AppIcon.icns"
cp "$CARGO_TARGET_DIR/$PROFILE/tape" "$STAGE/Contents/MacOS/tape"
IDENTITY="${TAPE_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development|Developer ID Application/ {print $2; exit}')}"
if [ -z "$IDENTITY" ]; then
  echo "warning: no signing identity found; ad-hoc signing (permissions reset on every rebuild)" >&2
  IDENTITY=-
fi
codesign --force --sign "$IDENTITY" --identifier "$BUNDLE_ID" "$STAGE"
codesign --verify --strict "$STAGE"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$STAGE/Contents/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns.new" && mv -f "$APP/Contents/Resources/AppIcon.icns.new" "$APP/Contents/Resources/AppIcon.icns"
cp "$STAGE/Contents/Info.plist" "$APP/Contents/Info.plist.new" && mv -f "$APP/Contents/Info.plist.new" "$APP/Contents/Info.plist"
mv -f "$STAGE/Contents/MacOS/tape" "$APP/Contents/MacOS/tape"
rm -f "$APP/Contents/MacOS/rec" "$APP/Contents/MacOS/rec-rs"  # pre-rename executables
rm -rf "$APP/Contents/_CodeSignature"
mv "$STAGE/Contents/_CodeSignature" "$APP/Contents/_CodeSignature"
rm -rf "$STAGE"
codesign --verify --strict "$APP"
# Re-register the bundle so Finder and the Dock pick up icon/Info.plist
# changes (LaunchServices caches them per bundle path).
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" || true
rm -f dist/rec dist/rec-rs  # pre-rename links
ln -sf "Tape.app/Contents/MacOS/tape" dist/tape
echo "built $APP (signed: $IDENTITY)"
echo "run:   dist/tape --help"
