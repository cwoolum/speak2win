#!/bin/bash
#
# Speak2 Uninstaller
# Removes Speak2 app data and downloaded models
#

echo "Speak2 Uninstaller"
echo "=================="
echo ""

# Check if running from correct location
APP_PATH="/Applications/Speak2.app"

# Items to remove
HUGGINGFACE_DIR="$HOME/Documents/huggingface"
FLUIDAUDIO_DIR="$HOME/Library/Application Support/FluidAudio"
PREFS_FILE="$HOME/Library/Preferences/com.zachswift.speak2.plist"

echo "This will remove:"
echo "  • Speak2.app from /Applications (if present)"
echo "  • WhisperKit models (~140MB) from ~/Documents/huggingface"
echo "  • Parakeet models (~600MB) from ~/Library/Application Support/FluidAudio"
echo "  • Speak2 preferences"
echo "  • Login item registration"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# Remove app
if [ -d "$APP_PATH" ]; then
    echo "Removing Speak2.app..."
    rm -rf "$APP_PATH"
else
    echo "Speak2.app not found in /Applications (skipping)"
fi

# Remove WhisperKit models
if [ -d "$HUGGINGFACE_DIR" ]; then
    echo "Removing WhisperKit models..."
    rm -rf "$HUGGINGFACE_DIR"
else
    echo "No WhisperKit models found (skipping)"
fi

# Remove FluidAudio/Parakeet models
if [ -d "$FLUIDAUDIO_DIR" ]; then
    echo "Removing Parakeet models..."
    rm -rf "$FLUIDAUDIO_DIR"
else
    echo "No Parakeet models found (skipping)"
fi

# Remove preferences
if [ -f "$PREFS_FILE" ]; then
    echo "Removing preferences..."
    rm -f "$PREFS_FILE"
else
    echo "No preferences file found (skipping)"
fi

# Remove from login items (best effort - may already be gone with app)
echo "Removing from login items..."
osascript -e 'tell application "System Events" to delete login item "Speak2"' 2>/dev/null || true

echo ""
echo "Speak2 has been uninstalled."
