# Ricky's World Cup Bracket 2026

A cross-platform Flutter app for a free 2026 FIFA World Cup bracket contest.
Users create a username profile, pick group advancers, fill the full knockout
bracket through the final, and compete on a public global leaderboard.

## Platforms

- iPhone
- Android
- Browser via Flutter Web
- Windows
- macOS

## App Architecture

- Flutter + Riverpod + GoRouter for the client app.
- Firebase Auth for anonymous login and optional account linking.
- Cloud Firestore for users, brackets, countries, fixtures, standings,
  leaderboard entries, reports, and admin overrides.
- Cloud Functions for API-Football sync, admin-only writes, scoring,
  lock reminders, and leaderboard rebuilds.
- Firebase custom claims for admin access.

The app currently runs locally with `InMemoryAppRepository`, so UI and tests work
before a real Firebase project is connected. Swap `appRepositoryProvider` to use
`FirebaseAppRepository` after running FlutterFire configuration.

## Firebase Setup

1. Create a Firebase project.
2. Enable Authentication providers:
   - Anonymous
   - Email/password if account recovery is desired
   - Google
   - Apple
3. Enable Firestore and Cloud Functions.
4. Install FlutterFire CLI:

   ```bash
   dart pub global activate flutterfire_cli
   ```

5. Configure all targets:

   ```bash
   flutterfire configure
   ```

6. Initialize Firebase in `main.dart` and provide `FirebaseAppRepository` through
   `appRepositoryProvider` when real credentials are ready.

## API-Football Secret

Cloud Functions expect an API-Football key stored as a Firebase secret:

```bash
firebase functions:secrets:set API_FOOTBALL_KEY
```

The scheduled sync uses:

- `fixtures?league=1&season=2026`
- `standings?league=1&season=2026`

API keys must never be stored in Flutter client code.

## Hidden Admin Access

The visible Admin button is intentionally hidden. Open the admin route by
long-pressing the app title or navigating directly to `/admin`.

The Flutter UI only unlocks admin screens when the signed-in Firebase user's
email is `rgw1985@hotmail.com`. That is the default admin email and can be
overridden for a different build with `ADMIN_EMAIL`:

```bash
flutter run -d chrome --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com
flutter build web --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com
```

The admin password is not stored in the app. Set the password for
`rgw1985@hotmail.com` in Firebase Authentication. Backend privileged writes
should still be protected with Firebase security rules and server-side admin
checks.

## Local Development

```bash
flutter pub get
flutter test
flutter run -d chrome
```

Start Firebase emulators after configuring Firebase:

```bash
firebase emulators:start
```

## Fixture Schedule Seeding

The app keeps the published 2026 schedule in `lib/src/data/fixture_seed_data.dart`.
Local sample fixtures use that same data. To inspect the generated Firestore
documents without writing anything:

```bash
cd functions
npm run seed:fixtures:dry-run
```

To seed the Firestore emulator, start the emulator first and then run:

```bash
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm run seed:fixtures
```

To seed production, authenticate application default credentials and set the
Firebase project id:

```bash
gcloud auth application-default login
cd functions
GCLOUD_PROJECT=your-firebase-project-id npm run seed:fixtures
```

The script writes 104 documents to `/fixtures/{matchId}` with `merge: true`, so
admin-entered scores are not cleared by schedule metadata reseeds unless the
seed data explicitly contains those fields.

## Staging Test Data

Local scripts can create deterministic staging data for end-to-end testing
without Cloud Functions. They refuse to write unless you target the Firestore
emulator or the staging Firebase project `testing-fe25d`.

Dry-run the commands first:

```bash
npm --prefix functions run test:brackets:dry-run -- --count=25 --seed=demo1
npm --prefix functions run test:results:dry-run -- --seed=demo1
npm --prefix functions run test:reset:dry-run -- --seed=demo1
```

Write staging test data:

```bash
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:brackets -- --count=25 --seed=demo1
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:results -- --seed=demo1
```

Reset staging test data and restore seeded fixtures with no scores:

```bash
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:reset -- --seed=demo1
```

Generated users, usernames, brackets, leaderboard entries, and audit rows are
marked with `isTestData: true` and `testRunId`, so reset only removes generated
test records. The reset also clears `/standings`, resets official results, and
restores `/fixtures` from `lib/src/data/fixture_seed_data.dart`.

## Staging Browser Smoke Tests

The `e2e/` package contains read-only Playwright smoke tests for the deployed
staging site. These tests sign in as the admin account, visit the main tabs, and
verify the admin sections render without clicking save or recalculation actions.

Install the E2E dependencies and Chromium once:

```bash
npm --prefix e2e install
npm --prefix e2e run install:browsers
```

Run against staging with admin credentials from environment variables:

```bash
E2E_ADMIN_EMAIL=rgw1985@hotmail.com \
E2E_ADMIN_PASSWORD='your-admin-password' \
npm --prefix e2e run test:staging
```

The default base URL is `https://testing-fe25d.web.app`. Override it when needed:

```bash
E2E_BASE_URL=https://testing-fe25d.web.app \
E2E_ADMIN_EMAIL=rgw1985@hotmail.com \
E2E_ADMIN_PASSWORD='your-admin-password' \
npm --prefix e2e run test:staging
```

Build platform targets:

```bash
flutter build web
flutter build ios
flutter build apk
flutter build macos
flutter build windows
```

Windows builds require running on Windows with the Flutter Windows toolchain.
iOS builds require macOS and Xcode signing configuration.

## Scoring

- Flat scoring: every correct pick is worth one point.
- Group stage scoring is advancement-only for first/second picks.
- Final score prediction is used as the leaderboard tiebreaker.
- Brackets autosave and lock at the first World Cup kickoff.

## Moderation

The MVP includes reserved usernames, user/bracket reports, and admin actions to
hide or rename abusive profiles. Comments and chat are intentionally excluded to
keep moderation small.
# world_cup_bracket

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
