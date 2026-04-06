#!/bin/bash
# Build, sign, notarize, and package AnnaExpenses.app
#
# Environment variables:
#   ANNA_EXPENSES_VERSION  — version string (default: 1.0.0)
#   SIGNING_IDENTITY       — override cert (use "-" for ad-hoc)
#   KEYCHAIN_PATH          — CI keychain with imported cert
#   KEYCHAIN_PASSWORD      — password to unlock CI keychain
#   APPLE_ID               — for notarization
#   APPLE_TEAM_ID          — for notarization
#   NOTARIZATION_PASSWORD  — app-specific password for notarization

set -e
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true
cd "$(dirname "$0")/.."

# Load .env if present
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

VERSION="${ANNA_EXPENSES_VERSION:-1.0.0}"
echo "Building AnnaExpenses v${VERSION}..."

# Generate Xcode project from project.yml
echo "Generating Xcode project..."
cd swift
xcodegen generate
cd ..

# Build
echo "Building with xcodebuild..."
xcodebuild \
  -project swift/AnnaExpenses.xcodeproj \
  -scheme AnnaExpenses \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  -destination 'platform=macOS' \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$VERSION" \
  build 2>&1 | tail -5

APP_NAME="AnnaExpenses"
BUILD_APP="build/DerivedData/Build/Products/Release/${APP_NAME}.app"
APP_DIR="build/${APP_NAME}.app"

echo "Copying built .app bundle..."
rm -rf "$APP_DIR"
# Using ditto for consistency with the rest of this script (lines 116, 145).
# cp -R also preserves xattrs on macOS and works fine for this app — tested 2026-04-06.
ditto "$BUILD_APP" "$APP_DIR"

CONTENTS="${APP_DIR}/Contents"
SPARKLE_FW="${CONTENTS}/Frameworks/Sparkle.framework"

# --- Code Signing ---
# Unlock CI keychain if present
if [ -n "$KEYCHAIN_PATH" ] && [ -n "$KEYCHAIN_PASSWORD" ]; then
    echo "Unlocking CI keychain..."
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
fi

IDENTITY="${SIGNING_IDENTITY:-}"
if [ -z "$IDENTITY" ]; then
    if [ -n "$KEYCHAIN_PATH" ]; then
        IDENTITY=$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
    else
        IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
    fi
    if [ -z "$IDENTITY" ]; then
        echo "ERROR: No Developer ID Application certificate found."
        echo "Install one from https://developer.apple.com/account/resources/certificates"
        echo "or set SIGNING_IDENTITY=\"-\" for ad-hoc signing (Gatekeeper will block the app)."
        exit 1
    fi
fi

if [ "$IDENTITY" = "-" ]; then
    echo "Code signing (ad-hoc)..."
else
    echo "Code signing with: ${IDENTITY}"
fi

CODESIGN_ARGS=(--force --sign "$IDENTITY" --timestamp)
if [ "$IDENTITY" != "-" ]; then
    CODESIGN_ARGS+=(--options runtime)
fi
if [ -n "$KEYCHAIN_PATH" ]; then
    CODESIGN_ARGS+=(--keychain "$KEYCHAIN_PATH")
fi

# Sign Sparkle framework components inside-out

find "$SPARKLE_FW" -name "*.xpc" -type d | while read -r xpc; do
    codesign "${CODESIGN_ARGS[@]}" "$xpc"
done

find "$SPARKLE_FW" -name "*.app" -type d | while read -r app; do
    codesign "${CODESIGN_ARGS[@]}" "$app"
done

for helper in "$SPARKLE_FW"/Versions/B/Autoupdate; do
    [ -f "$helper" ] && codesign "${CODESIGN_ARGS[@]}" "$helper"
done

codesign "${CODESIGN_ARGS[@]}" "$SPARKLE_FW"
codesign "${CODESIGN_ARGS[@]}" "$APP_DIR"

echo "Verifying code signature..."
codesign --verify --deep --strict "$APP_DIR"

# --- Notarization ---
if [ "$IDENTITY" != "-" ] && [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$NOTARIZATION_PASSWORD" ]; then
    echo "Submitting for notarization..."
    ZIP_PATH="build/${APP_NAME}-notarize.zip"
    ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
    NOTARY_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$NOTARIZATION_PASSWORD" \
        --wait 2>&1)
    echo "$NOTARY_OUTPUT"
    if echo "$NOTARY_OUTPUT" | grep -q "status: Invalid"; then
        SUBMISSION_ID=$(echo "$NOTARY_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
        echo "Notarization failed. Fetching log..."
        xcrun notarytool log "$SUBMISSION_ID" \
            --apple-id "$APPLE_ID" \
            --team-id "$APPLE_TEAM_ID" \
            --password "$NOTARIZATION_PASSWORD" 2>&1
        exit 1
    fi
    echo "Stapling notarization ticket..."
    xcrun stapler staple "$APP_DIR"
    rm -f "$ZIP_PATH"
    echo "Notarization complete."
else
    if [ "$IDENTITY" != "-" ]; then
        echo "Skipping notarization (set APPLE_ID, APPLE_TEAM_ID, NOTARIZATION_PASSWORD to enable)"
    fi
fi

if [ -z "$CI" ]; then
    echo "Installing to /Applications..."
    rm -rf "/Applications/${APP_NAME}.app"
    ditto "$APP_DIR" "/Applications/${APP_NAME}.app"
    echo "Done! Installed at /Applications/${APP_NAME}.app"
else
    echo "Done! App bundle at ${APP_DIR}"
fi
