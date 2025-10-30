#!/bin/bash
# Install Moplug Send Motion to /Applications and clear icon cache

set -e

echo "📦 Installing Moplug Send Motion..."
echo ""

# Check if build exists
if [ ! -d "build/Release/Moplug-Send-Motion.app" ]; then
    echo "❌ Build not found. Please run ./quick_build.sh first"
    exit 1
fi

# 1. Remove old app
echo "Step 1: Removing old installation..."
sudo rm -rf "/Applications/Moplug Send Motion.app"
echo "  ✅ Done"

# 2. Install new app
echo "Step 2: Installing new app..."
sudo cp -R "build/Release/Moplug-Send-Motion.app" "/Applications/Moplug Send Motion.app"
echo "  ✅ Installed to /Applications/Moplug Send Motion.app"

# 3. Clear icon cache
echo "Step 3: Clearing Finder icon cache..."
sudo rm -rf /Library/Caches/com.apple.iconservices.store
echo "  ✅ Icon cache cleared"

# 4. Rebuild LaunchServices database
echo "Step 4: Rebuilding LaunchServices database..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user >/dev/null 2>&1
echo "  ✅ LaunchServices rebuilt"

# 5. Restart Finder
echo "Step 5: Restarting Finder..."
killall Finder
echo "  ✅ Finder restarted"

echo ""
echo "✅ Installation complete!"
echo ""
echo "📍 App location: /Applications/Moplug Send Motion.app"
echo "🎨 Icon should now be visible in Finder"
echo ""
