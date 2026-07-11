#!/usr/bin/env bash
# Post-upload TestFlight install steps on iPhone.
set -euo pipefail

cat <<'EOF'
==> Install Accountability on iPhone via TestFlight

Prerequisites:
  • IPA uploaded to App Store Connect and processing finished (~10–30 min)
  • Apple Developer Program membership
  • TestFlight app installed on iPhone (App Store)

Steps:

1. App Store Connect → My Apps → Accountability → TestFlight

2. Internal testing (fastest — no beta review):
   • TestFlight → Internal Testing → + → create group
   • Add yourself as internal tester (same Apple ID as developer team)
   • Select the latest build → Save

3. On iPhone:
   • Open email invite OR TestFlight app
   • Tap Install for Accountability
   • First launch: allow Location + Notifications

4. Verify push (optional):
   • Sign in → complete onboarding permissions
   • Firestore console → users/{uid} → fcmToken should exist

5. External testers (optional — requires Beta App Review):
   • TestFlight → External Testing → add testers by email
   • Submit build for review (~24–48 hours)

EOF
