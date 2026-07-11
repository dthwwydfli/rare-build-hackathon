# Demo Day Checklist

Use this script when rehearsing the full E2E flow with Person A and Person B.

## Pre-demo setup

```bash
flutterfire configure
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
flutter run
```

## Two-device demo (5 minutes)

### Device 1 — Alex (user at risk)

1. Sign up as `alex@test.com`
2. Enable location + notifications (+ Usage Access on Android)
3. Create commitment: **"No betting shops"** (type: Location)
4. Create group **"Support Circle"** — note invite code
5. Tap **Demo breach** → **Simulate Location breach**

### Device 2 — Sam (friend)

1. Sign up as `sam@test.com`
2. Join group with invite code
3. Enable notifications
4. Receive push: "Alex may need support"
5. Open **Alerts** tab → tap breach → send "You've got this"

### Verify on Device 1

1. Alex receives support push notification
2. Home screen shows message under **Recent support**
3. Firestore console shows `breach_events` and `support_messages` docs

## Fallbacks if live detection fails

| Issue | Fallback |
|-------|----------|
| Location not triggering | Use breach simulator (FAB on home) |
| Android app detection | Use simulator → App breach |
| iOS app detection | Use simulator (real UsageStats blocked) |
| Push not arriving | Check `users/{id}.fcmToken` in Firestore |
| Function dedupe error | Deploy indexes: `firebase deploy --only firestore:indexes` |

## Known platform limits (tell judges)

- iOS: real app usage monitoring requires Apple Family Controls entitlement
- URL/email/SMS monitoring: Phase 2 (OS restrictions)
- Payment: simulated for hackathon; Open Banking in Phase 2
