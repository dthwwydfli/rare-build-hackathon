#!/usr/bin/env bash
# One-time Firebase + backend setup for TestFlight builds.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="$PATH:$HOME/.pub-cache/bin"

BUNDLE_ID="${IOS_BUNDLE_ID:-com.istiaqabdullah.accountability}"

echo "==> TestFlight setup (bundle ID: $BUNDLE_ID)"

if ! command -v flutter &>/dev/null; then
  echo "Flutter not found. Install from https://docs.flutter.dev/get-started/install"
  exit 1
fi

if ! command -v dart &>/dev/null; then
  echo "Dart not found."
  exit 1
fi

echo "==> Installing local Firebase CLI (if needed)"
npm install --silent 2>/dev/null || npm install

echo "==> Activating FlutterFire CLI"
dart pub global activate flutterfire_cli

if ! npx firebase login:list 2>/dev/null | grep -q "Authorized"; then
  echo ""
  echo "Firebase is not logged in."
  if [[ -t 0 ]]; then
    echo "Starting interactive login..."
    npx firebase login
  else
    echo "Run this in your terminal (requires browser sign-in):"
    echo "  cd $ROOT && npx firebase login"
    echo "Then re-run: ./scripts/testflight_setup.sh"
    exit 1
  fi
fi

echo "==> Configuring Firebase for Flutter (iOS bundle: $BUNDLE_ID)"
flutterfire configure \
  --yes \
  --platforms=ios,android,web \
  --ios-bundle-id="$BUNDLE_ID" \
  --out=lib/firebase_options.dart

echo "==> Installing Cloud Functions dependencies"
(cd functions && npm install)

echo "==> Deploying Firestore rules, indexes, and Cloud Functions"
npx firebase deploy --only firestore:rules,firestore:indexes,functions

echo ""
echo "==> Firebase setup complete."
echo "Next steps:"
echo "  1. Register App ID '$BUNDLE_ID' in Apple Developer portal"
echo "  2. Copy ios/Flutter/Signing.xcconfig.example → ios/Flutter/Signing.xcconfig"
echo "  3. Set DEVELOPMENT_TEAM in Signing.xcconfig"
echo "  4. Upload APNs .p8 key to Firebase Console → Cloud Messaging"
echo "  5. Run: ./scripts/testflight_release.sh"
