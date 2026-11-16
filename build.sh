#!/bin/zsh
# Basic Breath Exercise — .app paketini derler.
set -e
cd "$(dirname "$0")"

APP="Basic Breath Exercise.app"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/BasicBreathExercise "$APP/Contents/MacOS/BasicBreathExercise"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Basic Breath Exercise</string>
    <key>CFBundleDisplayName</key><string>Basic Breath Exercise</string>
    <key>CFBundleIdentifier</key><string>com.bbe.BasicBreathExercise</string>
    <key>CFBundleExecutable</key><string>BasicBreathExercise</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Hazır: $PWD/$APP"
