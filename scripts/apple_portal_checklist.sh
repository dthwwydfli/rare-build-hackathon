#!/usr/bin/env bash
# Prints Apple Developer + App Store Connect checklist for TestFlight.
set -euo pipefail

BUNDLE_ID="${IOS_BUNDLE_ID:-com.istiaqabdullah.accountability}"

cat <<EOF
==> Apple Developer portal checklist (manual, one-time)

Bundle ID: $BUNDLE_ID

1. Apple Developer Program
   https://developer.apple.com/programs/enroll/
   (99 USD/year — required for TestFlight)

2. Register App ID
   https://developer.apple.com/account/resources/identifiers/list
   → Identifiers → + → App IDs
   → Bundle ID: $BUNDLE_ID
   → Capabilities:
      • Push Notifications
      • Sign in with Apple
      • Background Modes (Location, Remote notifications, Background fetch)

3. Create App Store Connect app
   https://appstoreconnect.apple.com/apps
   → + → New App → iOS
   → Name: Accountability
   → Bundle ID: $BUNDLE_ID
   → SKU: accountability-2026 (any unique string)

4. APNs key for Firebase push (TestFlight uses production)
   https://developer.apple.com/account/resources/authkeys/list
   → + → Apple Push Notifications service (APNs)
   → Download .p8 (one-time download)
   → Firebase Console → Project Settings → Cloud Messaging
   → Apple app configuration → Upload .p8 + Key ID + Team ID

5. Xcode signing
   open ios/Runner.xcworkspace
   → Runner target → Signing & Capabilities
   → Team: your paid developer team
   → Bundle Identifier: $BUNDLE_ID

6. TestFlight on iPhone
   → Install TestFlight from App Store
   → App Store Connect → TestFlight → Internal Testing
   → Add yourself → open invite on iPhone → Install

EOF
