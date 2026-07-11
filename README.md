# Accountability App

Gambling accountability Flutter app with commitments, friend groups, breach detection, and peer support notifications.

## Quick start

```bash
# 1. Install Flutter: https://docs.flutter.dev/get-started/install
# 2. Generate platform files if needed
flutter create . --project-name accountability_app

# 3. Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Install dependencies
flutter pub get
cd functions && npm install && cd ..

# 5. Deploy Firebase backend
firebase login
firebase deploy --only firestore:rules,firestore:indexes,functions

# 6. Run the app
flutter run
```

## Two-person split

| Person A — Mobile & Social | Person B — Detection & Backend |
|---|---|
| `lib/features/auth/` | `functions/` |
| `lib/features/commitments/` | `lib/services/detection/` |
| `lib/features/groups/` | `lib/data/repositories/` |
| `lib/features/support/` | `assets/data/` |
| `lib/core/notifications/` | `lib/features/dev/breach_simulator.dart` |
| `lib/features/onboarding/` | `firestore.rules` |

Shared contract: `lib/domain/` (models + repository interfaces)

## Demo flow

1. Sign up → enable permissions
2. Create commitment ("No betting shops or gambling apps")
3. Create friend group → share invite code → friend joins on second device
4. Open **Demo breach** (FAB on home) → simulate location breach
5. Friend sees alert in **Alerts** tab → sends support message
6. User receives support notification

## Firebase collections

- `users` — profile + FCM token
- `commitments` — user goals with rules
- `groups` — friend circles with invite codes
- `breach_events` — detection signals (triggers Cloud Functions)
- `support_messages` — peer encouragement (triggers support notification)

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full system design, [docs/INTEGRATION.md](docs/INTEGRATION.md) for the E2E test guide, and [docs/DEMO_CHECKLIST.md](docs/DEMO_CHECKLIST.md) for demo day rehearsal.
