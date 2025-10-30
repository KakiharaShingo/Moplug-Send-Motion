#!/bin/bash
# Quick Build Script - Moplug Send Motion
# Usage: ./quick_build.sh

set -e

echo "🔨 Building Moplug Send Motion..."
xcodebuild -project Moplug-Send-Motion.xcodeproj -configuration Release build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi
    echo "✅ Build completed successfully!"
    echo ""
    echo "📦 Built app location:"
    echo "   ./build/Release/Moplug Send Motion.app"
    echo ""
    echo "🚀 To run the app:"
    echo "   ./run_latest.sh"
    echo ""
    echo "📥 To install to /Applications:"
    echo "   ./install_latest.sh"
else
    echo "❌ Build failed!"
    exit 1
fi
