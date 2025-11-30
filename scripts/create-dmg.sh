#!/bin/bash
set -euo pipefail

APP_NAME="Speak2"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Get version from git tag or default
VERSION="${GITHUB_REF_NAME:-v1.0.0}"
VERSION="${VERSION#v}"  # Remove 'v' prefix if present

DMG_NAME="$APP_NAME-v$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
VOLUME_NAME="$APP_NAME $VERSION"
DMG_TEMP="$BUILD_DIR/dmg_temp"

echo "Creating DMG: $DMG_NAME"

# Clean up any previous temp directory
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -R "$APP_BUNDLE" "$DMG_TEMP/"

# Create symlink to Applications
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$DMG_TEMP"

echo "DMG created at $DMG_PATH"
