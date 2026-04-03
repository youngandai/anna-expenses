#!/bin/bash
set -e

cd "$(dirname "$0")/swift"

echo "==> Generating Xcode project..."
xcodegen generate

echo "==> Building AnnaExpenses (Release)..."
xcodebuild \
  -project AnnaExpenses.xcodeproj \
  -scheme AnnaExpenses \
  -configuration Release \
  -derivedDataPath build \
  clean build \
  2>&1 | tail -5

APP_PATH="build/Build/Products/Release/AnnaExpenses.app"

if [ ! -d "$APP_PATH" ]; then
  echo "ERROR: Build failed — app not found at $APP_PATH"
  exit 1
fi

echo "==> Copying to /Applications..."
rm -rf /Applications/AnnaExpenses.app
cp -R "$APP_PATH" /Applications/AnnaExpenses.app

echo "==> Done! AnnaExpenses is now in /Applications."
echo "    Open it with: open /Applications/AnnaExpenses.app"
