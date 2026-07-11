#!/usr/bin/env bash
set -euo pipefail

echo "==> Accountability App bootstrap"

if ! command -v flutter &>/dev/null; then
  echo "Flutter not found. Install from https://docs.flutter.dev/get-started/install"
  exit 1
fi

# Ensure platform folders exist
if [ ! -f "android/app/src/main/kotlin/com/example/accountability_app/MainActivity.kt" ]; then
  flutter create . --project-name accountability_app --org com.example
fi

flutter pub get

if command -v firebase &>/dev/null; then
  echo "==> Installing Cloud Functions dependencies"
  (cd functions && npm install)
  echo "Run: flutterfire configure && firebase deploy --only firestore:rules,firestore:indexes,functions"
else
  echo "Firebase CLI not found. Install: npm install -g firebase-tools"
fi

echo "==> Done. Next steps for TestFlight:"
echo "  npm run testflight:setup    # Firebase + backend"
echo "  npm run testflight:release  # Build IPA after Xcode signing"
