#!/usr/bin/env bash
# End-to-end TestFlight pipeline with checkpoints.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Accountability TestFlight pipeline"
echo ""

step=1
run_step() {
  echo "[$step/5] $1"
  step=$((step + 1))
}

run_step "Firebase + backend setup"
if ! bash scripts/testflight_setup.sh; then
  echo ""
  echo "If Firebase login is needed, run in Terminal:"
  echo "  cd $ROOT && npx firebase login && npm run testflight:setup"
  exit 1
fi

echo ""
run_step "Apple Developer portal (manual checklist)"
bash scripts/apple_portal_checklist.sh
echo ""
read -r -p "Completed Apple portal setup? Press Enter to continue..."

echo ""
run_step "APNs + Firebase Cloud Messaging (manual checklist)"
bash scripts/apns_firebase_checklist.sh
echo ""
read -r -p "Uploaded APNs key to Firebase? Press Enter to continue..."

if [[ ! -f ios/Flutter/Signing.xcconfig ]]; then
  cp ios/Flutter/Signing.xcconfig.example ios/Flutter/Signing.xcconfig
  echo ""
  echo "Created ios/Flutter/Signing.xcconfig — edit DEVELOPMENT_TEAM, then re-run:"
  echo "  npm run testflight:release"
  open ios/Runner.xcworkspace
  exit 0
fi

echo ""
run_step "Build and upload IPA"
bash scripts/testflight_release.sh

echo ""
run_step "Install on iPhone"
bash scripts/testflight_install_checklist.sh
