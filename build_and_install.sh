#!/bin/bash
set -e

echo "🔨 Building Moplug Send Motion..."

# Clean first
xcodebuild -project Moplug-Send-Motion.xcodeproj \
    -configuration Release \
    clean

# Build the project
xcodebuild -project Moplug-Send-Motion.xcodeproj \
    -configuration Release \
    build

echo "✓ Build complete"

# Create .fcpxdest file
echo "📄 Creating .fcpxdest file..."
./create_fcpxdest_from_template.sh

# Install .app
BUILD_APP_NAME="Moplug-Send-Motion.app"
INSTALL_APP_NAME="Moplug Send Motion.app"
BUILD_PATH="build/Release/$BUILD_APP_NAME"

if [ -d "$BUILD_PATH" ]; then
    echo "📦 Installing application..."
    sudo rm -rf "/Applications/$INSTALL_APP_NAME"
    sudo cp -R "$BUILD_PATH" "/Applications/$INSTALL_APP_NAME"

    # Ad-hoc sign the application
    echo "🔐 Signing application with ad-hoc signature..."
    sudo codesign --force --deep --sign - "/Applications/$INSTALL_APP_NAME"

    # Remove quarantine attributes
    echo "🔓 Removing quarantine attributes..."
    sudo xattr -rc "/Applications/$INSTALL_APP_NAME"

    echo "✓ Installed to /Applications/$INSTALL_APP_NAME"
else
    echo "❌ Build output not found at $BUILD_PATH"
    exit 1
fi

# Install .fcpxdest
DEST_FILE="/tmp/Moplug-Send-Motion.fcpxdest"
DEST_DIR="/Library/Application Support/ProApps/Share Destinations"

if [ -f "$DEST_FILE" ]; then
    echo "📦 Installing share destination..."
    sudo mkdir -p "$DEST_DIR"
    sudo cp "$DEST_FILE" "$DEST_DIR/"
    echo "✓ Installed to $DEST_DIR/Moplug-Send-Motion.fcpxdest"
else
    echo "❌ .fcpxdest file not found"
    exit 1
fi

# Copy .sdef file to app resources
SDEF_SRC="Source/Resources/OSAScriptingDefinition.sdef"
SDEF_DEST="/Applications/$INSTALL_APP_NAME/Contents/Resources/OSAScriptingDefinition.sdef"

if [ -f "$SDEF_SRC" ]; then
    echo "📄 Installing scripting definition..."
    sudo mkdir -p "/Applications/$INSTALL_APP_NAME/Contents/Resources"
    sudo cp "$SDEF_SRC" "$SDEF_DEST"
    echo "✓ Installed scripting definition"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Restart Final Cut Pro if it's running"
echo "2. In Final Cut Pro, go to File > Share"
echo "3. Look for 'Moplug Send Motion' in the destinations list"
echo ""
echo "To test:"
echo "1. Select a clip or timeline in FCP"
echo "2. Choose File > Share > Moplug Send Motion"
echo "3. The app should open and process the FCPXML"
