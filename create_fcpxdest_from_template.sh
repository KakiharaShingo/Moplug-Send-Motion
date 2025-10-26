#!/bin/bash
set -e

echo "📄 Creating .fcpxdest from Xsend Motion template..."

# Read Xsend Motion's fcpxdest as binary
XSEND_DEST="/Library/Application Support/ProApps/Share Destinations/Xsend Motion.fcpxdest"
TEMP_XML="/tmp/xsend_template.xml"
OUTPUT_DEST="/tmp/Moplug-Send-Motion.fcpxdest"

# Convert to XML for editing
plutil -convert xml1 -o "$TEMP_XML" "$XSEND_DEST"

# Replace Xsend Motion references with Moplug Send Motion
sed -i '' 's/Xsend Motion/Moplug Send Motion/g' "$TEMP_XML"
sed -i '' 's/Xsend%20Motion/Moplug%20Send%20Motion/g' "$TEMP_XML"
sed -i '' 's/com.automaticduck.Xsend-Motion/com.moplug.sendmotion/g' "$TEMP_XML"

# Replace the app path
sed -i '' 's|/Applications/Xsend%20Motion.app|/Applications/Moplug%20Send%20Motion.app|g' "$TEMP_XML"

# Generate new UUID
NEW_UUID=$(uuidgen)
# Find and replace the UUID in the XML (it's a string value)
sed -i '' "s/<string>[0-9A-F-]\{36\}<\/string>/<string>$NEW_UUID<\/string>/" "$TEMP_XML"

# Convert back to binary plist
plutil -convert binary1 -o "$OUTPUT_DEST" "$TEMP_XML"

# Clean up
rm "$TEMP_XML"

echo "✓ Created $OUTPUT_DEST"
echo ""
echo "Now install with:"
echo "sudo cp '$OUTPUT_DEST' '/Library/Application Support/ProApps/Share Destinations/'"
