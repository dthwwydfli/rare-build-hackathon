#!/usr/bin/env bash
# Build release IPA and upload to App Store Connect for TestFlight.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="$PATH:$HOME/.pub-cache/bin"

BUNDLE_ID="${IOS_BUNDLE_ID:-com.istiaqabdullah.accountability}"
SIGNING_XCCONFIG="ios/Flutter/Signing.xcconfig"
EXPORT_PLIST="ios/ExportOptions.plist"

echo "==> TestFlight release build (bundle ID: $BUNDLE_ID)"

if [[ ! -f "$SIGNING_XCCONFIG" ]]; then
  echo "Missing $SIGNING_XCCONFIG"
  echo "Copy ios/Flutter/Signing.xcconfig.example and set DEVELOPMENT_TEAM."
  exit 1
fi

if grep -q "YOUR_TEAM_ID" "$SIGNING_XCCONFIG"; then
  echo "Set DEVELOPMENT_TEAM in $SIGNING_XCCONFIG before building."
  exit 1
fi

if grep -q "YOUR_IOS_API_KEY" lib/firebase_options.dart 2>/dev/null; then
  echo "Firebase is not configured. Run: ./scripts/testflight_setup.sh"
  exit 1
fi

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple"; then
  echo ""
  echo "No code signing certificate found."
  echo "Open Xcode → Settings → Accounts → add your Apple ID → Download Manual Profiles."
  echo "Or open ios/Runner.xcworkspace, select Runner target → Signing & Capabilities → select Team."
  exit 1
fi

echo "==> Flutter dependencies"
flutter pub get

echo "==> CocoaPods"
(cd ios && pod install)

echo "==> Building release IPA"
flutter build ipa \
  --release \
  --export-options-plist="$EXPORT_PLIST"

IPA_PATH="$(find build/ios/ipa -name '*.ipa' 2>/dev/null | head -1)"
if [[ -z "$IPA_PATH" ]]; then
  echo "IPA not found under build/ios/ipa"
  exit 1
fi

echo ""
echo "==> IPA built: $IPA_PATH"
echo ""
echo "Upload options:"
echo "  A) Transporter app (Mac App Store) — drag and drop the IPA"
echo "  B) Xcode Organizer — Product → Archive → Distribute App"
echo "  C) CLI:"
echo "     xcrun altool --upload-app -f \"$IPA_PATH\" -t ios -u YOUR_APPLE_ID -p @keychain:AC_PASSWORD"
echo ""
echo "After upload (~10–30 min processing):"
echo "  App Store Connect → TestFlight → Internal Testing → add yourself → Install on iPhone"
