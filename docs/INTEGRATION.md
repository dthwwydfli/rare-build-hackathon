# End-to-end integration guide

This document describes how Person A (UI) and Person B (detection/backend) connect.

## Shared contract

Both engineers implement against:

- `lib/domain/models/` — data types
- `lib/domain/repositories/` — abstract interfaces

Person B implements in `lib/data/repositories/`. Person A consumes via Riverpod providers in `lib/core/providers/repository_providers.dart`.

## Data flow: breach → friend alert

```
DetectionCoordinator (B)
  → FirestoreBreachRepository.createBreach()
  → breach_events/{id} document created
  → Cloud Function onBreachCreated (B)
  → FCM multicast to group members
  → NotificationService (A) receives push
  → NotificationRouter navigates to /breach/:eventId
  → BreachDetailScreen (A) shows alert + support composer
```

## Data flow: support message → user notification

```
BreachDetailScreen (A)
  → BreachRepository.sendSupport()
  → support_messages/{id} document created
  → Cloud Function onSupportCreated (B)
  → FCM to breach user
  → User sees support on home screen
```

## Integration checklist

- [x] Domain models match Firestore schema
- [x] Repository interfaces implemented in `lib/data/repositories/`
- [x] Riverpod providers wire repos to UI
- [x] GoRouter auth redirect guards screens
- [x] FCM token saved to `users/{id}.fcmToken` on login
- [x] Cloud Functions trigger on `breach_events` and `support_messages`
- [x] Breach simulator writes real Firestore docs for demo
- [x] Notification deep links route to breach detail

## Manual E2E test (two devices)

### Device 1 (user at risk)

1. Sign up as `user@test.com`
2. Create commitment: "No betting shops" (type: Location)
3. Create group "Support Circle" — note invite code
4. Enable location + notifications

### Device 2 (friend)

1. Sign up as `friend@test.com`
2. Join group with invite code
3. Enable notifications

### Trigger breach

On Device 1: tap **Demo breach** FAB → **Simulate Location breach**

### Verify

1. `breach_events` doc appears in Firestore console
2. Device 2 receives push: "{user} may need support"
3. Device 2: Alerts tab → tap breach → send support message
4. `support_messages` doc created
5. Device 1 receives push with support text
6. Device 1 home shows support in "Recent support"

## Firebase setup required

```bash
flutterfire configure          # generates lib/firebase_options.dart
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Without Firebase configured, set `useMockAuth = true` in `repository_providers.dart` for UI-only testing (no real push).
