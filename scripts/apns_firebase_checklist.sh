#!/usr/bin/env bash
# APNs + Firebase Cloud Messaging setup checklist for TestFlight push.
set -euo pipefail

BUNDLE_ID="${IOS_BUNDLE_ID:-com.istiaqabdullah.accountability}"

cat <<EOF
==> APNs setup for TestFlight (production push)

TestFlight builds use production APNs. Without this, auth may work but friend alerts will not.

1. Create APNs Auth Key (.p8)
   https://developer.apple.com/account/resources/authkeys/list
   → + → Apple Push Notifications service (APNs)
   → Key Name: Accountability APNs
   → Download .p8 file (only available once — store securely)

2. Note these values:
   • Key ID (10 chars, shown after creation)
   • Team ID (Membership → https://developer.apple.com/account → Team ID)

3. Upload to Firebase
   https://console.firebase.google.com/
   → Project Settings → Cloud Messaging tab
   → Apple app configuration → Upload
   → Select iOS app ($BUNDLE_ID)
   → APNs Authentication Key: upload .p8, enter Key ID + Team ID

4. Verify after TestFlight install
   • Sign in on iPhone
   • Allow notifications when prompted
   • Firestore → users/{uid} → fcmToken should be populated

Release entitlements in this repo use production APNs:
  ios/Runner/RunnerRelease.entitlements

EOF
