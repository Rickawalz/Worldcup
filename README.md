# Ricky's World Cup Bracket 2026

A cross-platform Flutter app for running a 2026 FIFA World Cup bracket contest.
Users create a profile, pick group advancers, fill the knockout bracket, export
their bracket as a PDF wallchart, and compete on a public leaderboard.

The app is designed to stay on the low-cost/free path: official match results,
standings, contest settings, and leaderboard recalculation are managed from an
in-app admin screen with Firestore writes instead of scheduled Cloud Functions.

## Features

- Dark World Cup dashboard UI for Home, Bracket, Standings, Schedule, Players,
  Chat, Profile, and Admin.
- Bracket picks with autosave, edit/resubmit support until lock, full knockout
  wallchart, and localized PDF export.
- Public Players tab with other users' submitted picks, flags, grouped cards,
  and score breakdowns.
- Schedule tab with date controls, kickoff time, teams, flags, status, scores,
  and venue details.
- Standings tab with calculated group tables, game cards, and a read-only
  official knockout bracket that fills from admin-entered scores.
- Admin tools for match results, group advancers, standings overrides,
  leaderboard recalculation, contest settings, and audit logs.
- English and Spanish localization for the main app and PDF export.

## Platforms

- Flutter Web
- iOS
- Android
- macOS
- Windows

## Architecture

- Flutter, Riverpod, and GoRouter for the client app.
- Firebase Auth for sign-in and account identity.
- Cloud Firestore for users, brackets, countries, fixtures, official results,
  standings, leaderboard entries, contest config, chat, reports, and audit logs.
- Firebase custom claims plus the configured admin email for admin access.
- Local Node.js scripts for fixture seeding and staging test data.
- Playwright for deployed staging smoke tests.

The manual admin path is the source of truth for official scores. Admin actions
write to Firestore and update derived data through app/repository logic. Cloud
Functions dependencies may exist in the package, but the launch workflow does not
require paid scheduled functions for score syncing.

## Prerequisites

- Flutter SDK with Dart `^3.7.2`.
- Firebase CLI if you want to run emulators or deploy Hosting.
- Node.js `20` for the `functions/` scripts.
- A Firebase project with Authentication and Firestore enabled.

Install Flutter dependencies:

```bash
flutter pub get
```

Install script dependencies when needed:

```bash
npm --prefix functions install
npm --prefix e2e install
```

## Running The App

Run locally in Chrome:

```bash
flutter run -d chrome --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com
```

Run on a connected device or another supported target:

```bash
flutter devices
flutter run -d <device-id> --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com
```

Start Firebase emulators when testing Firestore/Auth locally:

```bash
firebase emulators:start
```

## Build And Deploy

Build the web app:

```bash
flutter build web --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com
```

Deploy to Firebase Hosting:

```bash
firebase deploy --only hosting --project testing-fe25d
```

Build other platforms:

```bash
flutter build apk
flutter build ios
flutter build macos
flutter build windows
```

iOS builds require macOS and Xcode signing. Windows builds require the Flutter
Windows toolchain on Windows.

If a phone browser still shows an old version after deploy, clear that site's
Chrome/Safari data or test in an incognito/private tab. Flutter web apps can be
served from a cached bundle after a deploy.

## Admin Access

Open admin tools by navigating directly to `/admin` or by long-pressing the app
title. The default admin email is:

```text
rgw1985@hotmail.com
```

Admin access is protected by:

- The configured `ADMIN_EMAIL` build value.
- The signed-in Firebase user's email.
- Firebase admin custom claims/security rules for privileged data.

The admin password is not stored in this repository. Manage the account password
inside Firebase Authentication.

Admin sections include:

- Match results and game metadata.
- Confirm group advancers.
- Recalculate leaderboard.
- Contest settings such as lock time and accepting bracket submissions.
- Group standings override order.
- Admin audit log.

## Data Seeding And Staging Scripts

The published 2026 schedule lives in
`lib/src/data/fixture_seed_data.dart`. Local sample fixtures use the same data.

Dry-run fixture seeding:

```bash
npm --prefix functions run seed:fixtures:dry-run
```

Seed the Firestore emulator:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix functions run seed:fixtures
```

Seed a Firebase project after authenticating with application default
credentials:

```bash
gcloud auth application-default login
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run seed:fixtures
```

The fixture seed writes 104 `/fixtures/{matchId}` documents with `merge: true`.
Schedule metadata reseeds do not clear admin-entered scores unless the seed data
explicitly includes those fields.

### Staging Test Data

These scripts create deterministic data for staging or the emulator. They are
intended for demos and smoke tests, not production contest data.

Dry-run first:

```bash
npm --prefix functions run test:brackets:dry-run -- --count=25 --seed=demo1
npm --prefix functions run test:results:dry-run -- --seed=demo1
npm --prefix functions run test:reset:dry-run -- --seed=demo1
```

Write staging data:

```bash
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:brackets -- --count=25 --seed=demo1
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:results -- --seed=demo1
```

Reset generated staging data:

```bash
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:reset -- --seed=demo1
```

Generated records are marked with `isTestData: true` and `testRunId`, so reset
targets the generated users, usernames, brackets, leaderboard entries, audit
rows, standings, official results, and seeded fixture state for that run.

## Tests

Run all Flutter tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Run a focused test file:

```bash
flutter test test/features/bracket_pdf_builder_test.dart
```

### Domain Tests

Domain tests live in `test/domain/` and cover app logic that should work without
rendering the UI:

- `admin_access_test.dart`: admin email/claim access behavior.
- `admin_results_test.dart`: official results, fixture result metadata, and
  admin-related model behavior.
- `api_football_mapper_test.dart`: mapping API-style football responses into
  app fixture data.
- `app_strings_test.dart`: localized strings, including PDF title/credit text.
- `bracket_rules_test.dart`: official group membership, knockout slots,
  third-place mapping, and bracket validation.
- `chat_repository_test.dart`: in-memory repository flows for profiles, chat,
  bracket visibility, editable submitted brackets, admin sign-in, and standings
  recalculation.
- `country_flags_test.dart`: flag fallback behavior.
- `country_names_test.dart`: English/Spanish country display names.
- `sample_data_test.dart`: country and fixture seed completeness.
- `scoring_test.dart`: bracket scoring rules.
- `standings_calculator_test.dart`: calculated group standings.
- `username_validator_test.dart`: username validation and reserved names.

### Feature And Widget Tests

Feature tests live in `test/features/` and widget tests live in `test/widgets/`:

- `app_smoke_test.dart`: app startup, landing page, and core navigation smoke
  coverage.
- `bracket_pdf_builder_test.dart`: localized PDF wallchart generation,
  personalized title, credit, and flag-image path.
- `bracket_wallchart_test.dart`: bracket wallchart and fallback editor.
- `schedule_screen_test.dart`: daily schedule UI and match card display.
- `standings_screen_test.dart`: standings match cards, flags, scores, venue, and
  official knockout bracket rendering.
- `country_badge_test.dart`: country badge display variants.
- `dashboard_test.dart`: shared dashboard header/stat UI.

## Staging Browser Smoke Tests

The `e2e/` package contains read-only Playwright tests for the deployed staging
site. They sign in as the admin account, visit the main tabs, and verify admin
sections render without clicking save or recalculation actions.

Install dependencies and Chromium once:

```bash
npm --prefix e2e install
npm --prefix e2e run install:browsers
```

Run against the default staging URL, `https://testing-fe25d.web.app`:

```bash
E2E_ADMIN_EMAIL=rgw1985@hotmail.com \
E2E_ADMIN_PASSWORD='your-admin-password' \
npm --prefix e2e run test:staging
```

Run headed mode for debugging:

```bash
E2E_ADMIN_EMAIL=rgw1985@hotmail.com \
E2E_ADMIN_PASSWORD='your-admin-password' \
npm --prefix e2e run test:staging:headed
```

Override the base URL:

```bash
E2E_BASE_URL=https://testing-fe25d.web.app \
E2E_ADMIN_EMAIL=rgw1985@hotmail.com \
E2E_ADMIN_PASSWORD='your-admin-password' \
npm --prefix e2e run test:staging
```

Playwright outputs traces, screenshots, and videos on failure under the `e2e/`
test output folders.

## Useful Checks Before Commit Or Deploy

```bash
flutter analyze
flutter test
npm --prefix functions run lint
```

For staging E2E coverage, also run:

```bash
E2E_ADMIN_EMAIL=rgw1985@hotmail.com \
E2E_ADMIN_PASSWORD='your-admin-password' \
npm --prefix e2e run test:staging
```

## Notes

- Keep API keys and admin passwords out of Flutter client code and out of git.
- Use dry-run script commands before writing staging data.
- Keep the Admin screen as the manual fallback even if score-import scripts are
  added later.
- User-facing text should prefer "game" over "fixture"; internal model names may
  still use `Fixture` and `/fixtures`.
