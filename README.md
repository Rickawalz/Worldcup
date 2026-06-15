# Ricky's World Cup Bracket 2026

A cross-platform Flutter app for running a private 2026 FIFA World Cup bracket
pool. Friends create an account, pick which teams advance from each group, fill
out the full knockout bracket, and compete on a public leaderboard as real results
come in.

**Live site:** https://testing-fe25d.web.app

---

## What this app does

This is a **bracket contest manager**, not a live scores website. The core loop:

1. **Players** sign up, build their bracket, and submit before the contest locks.
2. **Official results** (group advancers, knockout winners, final score) are
   recorded by an admin or pulled automatically from [football-data.org](https://www.football-data.org/).
3. **Scores** are calculated from each player's picks vs. official results.
4. **Leaderboard** ranks everyone; players can browse each other's brackets.

The app covers the expanded **48-team, 12-group** 2026 World Cup format with
**104 games** (72 group stage + 32 knockout).

---

## How the contest works (player view)

### 1. Sign up and profile

- Firebase Authentication (email/password).
- Choose a unique username stored in Firestore.
- English or Spanish UI.

### 2. Build a bracket (`/bracket`)

Players make three kinds of picks:

| Pick type | What you choose |
|-----------|-----------------|
| **Group advancers** | Top 2 from each of 12 groups (A–L) + 8 best third-place teams |
| **Knockout winners** | Winner of every knockout game from Round of 32 through the Final |
| **Final tiebreaker** | Predicted final score (used to break ties on the leaderboard) |

- Picks **autosave** while editing.
- Bracket can be **edited and resubmitted** until the contest locks.
- Export a **PDF wallchart** of your picks (localized, with flags).

### 3. Browse the tournament

| Tab | Route | Purpose |
|-----|-------|---------|
| Home | `/` | Dashboard overview |
| Bracket | `/bracket` | Your picks |
| Standings | `/standings` | Live group tables + official knockout bracket |
| Schedule | `/amys-calendar` | All 104 games with times, scores, venues |
| Players | `/players` | Other users' submitted brackets and score breakdowns |
| Chat | `/chat` | Global contest chat |
| Profile | `/profile` | Account settings |
| Leaderboard | (via nav) | Rankings |

### 4. Submit and lock

- Contest **lock time** is set by admin (typically first kickoff).
- After lock, brackets become read-only.
- Only **submitted** brackets appear on the leaderboard.

---

## How scoring works

Scoring lives in `lib/src/domain/scoring.dart` and runs whenever the admin
recalculates the leaderboard (or Cloud Functions rebuild it after a result).

**Points per correct pick** is configurable (default set in contest config).

| Category | How points are earned |
|----------|----------------------|
| **Group stage** | +1 point per correctly picked team that actually advances (top 2 + best 8 thirds) |
| **Knockout** | +1 point per correctly picked knockout winner (each round) |
| **Tiebreaker** | Final score prediction distance breaks ties when total points are equal (lower distance wins) |

Official results come from `globalContest/current/officialResults/current`:

- `advancingCountryIds` — which 32 teams advanced from groups
- `knockoutWinnersBySlot` — winner of each knockout slot (`m73`–`m104`)
- `finalChampionScore` / `finalRunnerUpScore` — for tiebreaker

---

## How match results get into the app

There are **two paths** for official data. Both write to the same Firestore
documents; they never fight each other.

```
                    ┌─────────────────────┐
                    │  /fixtures/m1–m104 │
                    │  (scores, status)   │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼────────┐  ┌────▼─────┐  ┌──────▼──────┐
     │ Admin manual    │  │ football │  │  Fixture    │
     │ entry (/admin)  │  │ -data.org│  │  seed data  │
     └────────┬────────┘  │ auto sync│  └─────────────┘
              │           └────┬─────┘
              │                │
              └────────┬───────┘
                       │
            ┌──────────▼──────────┐
            │ Cloud Functions      │
            │ side effects:        │
            │ • group standings    │
            │ • knockout winners   │
            │ • leaderboard rebuild│
            └─────────────────────┘
```

### Admin manual entry (always available)

Open `/admin` (long-press the app title, or navigate directly). Admin can:

- Enter game scores and status
- Confirm group advancers
- Override standings order
- Set contest lock time and submission rules
- **Recalculate leaderboard**
- View audit log

**Admin wins:** if a game was manually saved by admin (`updatedBy` is set),
automatic sync **skips** that game.

### Automatic score sync (free, via football-data.org)

Cloud Functions pull World Cup data from the **free** football-data.org tier
(World Cup is included at no cost).

| Trigger | Behavior |
|---------|----------|
| **Scheduled** | Every 15 min, but only during active game windows (~10 min before kickoff through ~2.5 hr after) |
| **Manual** | Admin → Settings → **Sync now** |

Each sync:

1. Fetches World Cup teams + matches from football-data.org
2. Maps API teams to local countries by name / abbreviation (TLA)
3. Matches games to `/fixtures/m1`–`m104` by team pair + kickoff date
4. Merges `status`, `homeScore`, `awayScore`, `winnerCountryId`
5. Triggers standings recalc, knockout official results, and leaderboard rebuild

**Knockout games** (`m73`–`m104`) are not matched until teams are known — those
fixtures start without `homeCountryId`/`awayCountryId` in seed data. Group-stage
games (`m1`–`m72`) sync automatically.

Sync status is stored at `/syncState/current`.

---

## Architecture

| Layer | Technology |
|-------|------------|
| Client | Flutter, Riverpod, GoRouter |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Backend | Cloud Functions (Node.js 20, TypeScript) |
| Hosting | Firebase Hosting (Flutter web build) |
| Score API | [football-data.org](https://www.football-data.org/) (free tier) |

### Key source files

| Area | Location |
|------|----------|
| App routes & shell | `lib/src/app.dart` |
| Screens | `lib/src/features/` |
| Domain models | `lib/src/domain/models.dart` |
| Bracket rules (groups, slots) | `lib/src/domain/bracket_rules.dart` |
| Scoring | `lib/src/domain/scoring.dart` |
| Standings calculator | `functions/src/standings-calculator.ts` |
| Score sync | `functions/src/sync-world-cup.ts`, `football-data-client.ts` |
| Cloud Functions entry | `functions/src/index.ts` |
| 2026 schedule seed | `lib/src/data/fixture_seed_data.dart` |
| Firestore rules | `firestore.rules` |

### Firestore collections (main)

| Path | Contents |
|------|----------|
| `/users/{userId}` | Profile, username, settings |
| `/usernames/{name}` | Username uniqueness |
| `/countries/{id}` | 48 teams, flags, abbreviations |
| `/fixtures/m1`–`m104` | Schedule, scores, status, venues |
| `/standings/{groupId}` | Calculated group tables |
| `/globalContest/current/config/current` | Lock time, points per pick |
| `/globalContest/current/officialResults/current` | Advancers, knockout winners, final score |
| `/globalContest/current/brackets/{userId}` | Each player's bracket |
| `/leaderboards/global/entries/{userId}` | Public rankings |
| `/globalChat/{messageId}` | Chat messages |
| `/syncState/current` | Last sync time, counts, errors |
| `/adminAuditLogs/{id}` | Admin action history |

---

## Features

- Dark World Cup dashboard UI
- Bracket picks with autosave, edit/resubmit until lock, PDF wallchart export
- Public Players tab with other users' picks and score breakdowns
- Schedule tab with dates, kickoffs, teams, flags, scores, venues
- Standings with calculated group tables and official knockout bracket
- Admin tools for results, advancers, standings, contest settings, audit log
- English and Spanish localization (UI + PDF)

## Platforms

Flutter Web · iOS · Android · macOS · Windows

---

## Score sync setup

### 1. Get a free API token

Register at [football-data.org/client/register](https://www.football-data.org/client/register)
and copy your token from the dashboard.

### 2. Store in Firebase secrets

Requires Firebase **Blaze** plan for scheduled/callable functions.

```bash
firebase functions:secrets:set FOOTBALL_DATA_TOKEN --project testing-fe25d
```

### 3. Deploy functions

```bash
firebase deploy --only functions --project testing-fe25d
```

### 4. Seed countries (first-time setup)

```bash
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run seed:countries
```

Team IDs are enriched from football-data.org on each sync — no manual ID mapping
needed.

### Rate limits

Free tier: **10 requests/minute**. Match-window polling + manual sync stay well
within this for a small pool (~5–20 users).

### Diagnose sync locally

```bash
gcloud auth application-default login
FOOTBALL_DATA_TOKEN='your-token' \
GOOGLE_CLOUD_QUOTA_PROJECT=testing-fe25d \
GCLOUD_PROJECT=testing-fe25d \
node functions/scripts/diagnose-sync.mjs
```

---

## Prerequisites

- Flutter SDK with Dart `^3.7.2`
- Firebase CLI (emulators / deploy)
- Node.js 20 (`functions/` scripts and Cloud Functions)
- Firebase project with Auth + Firestore enabled

```bash
flutter pub get
npm --prefix functions install
npm --prefix e2e install   # optional, for browser smoke tests
```

---

## Running locally

```bash
flutter run -d chrome --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com
```

Other devices:

```bash
flutter devices
flutter run -d <device-id> --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com
```

Firebase emulators:

```bash
firebase emulators:start
```

---

## Build and deploy

```bash
# Web build
flutter build web --dart-define=ADMIN_EMAIL=rgw1985@hotmail.com

# Deploy hosting + functions
firebase deploy --only hosting,functions --project testing-fe25d
```

Other platforms: `flutter build apk` · `flutter build ios` · `flutter build macos` · `flutter build windows`

After deploy, hard-refresh or use incognito if the browser shows a cached bundle.

---

## Admin access

- **URL:** `/admin` or long-press the app title
- **Email:** `rgw1985@hotmail.com` (set via `--dart-define=ADMIN_EMAIL=...`)
- **Auth:** Firebase sign-in + admin custom claim or configured admin email

Grant admin claim:

```bash
GOOGLE_CLOUD_QUOTA_PROJECT=testing-fe25d \
GCLOUD_PROJECT=testing-fe25d \
npm --prefix functions run set:admin-claim -- --email=rgw1985@hotmail.com
```

Admin password is managed in Firebase Authentication, not in this repo.

---

## Data seeding

Official 2026 schedule: `lib/src/data/fixture_seed_data.dart` (104 games).

```bash
# Dry run
npm --prefix functions run seed:fixtures:dry-run

# Seed emulator
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix functions run seed:fixtures

# Seed production
gcloud auth application-default login
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run seed:fixtures
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run seed:countries
```

Fixture seed uses `merge: true` — reseeding schedule metadata does not wipe
admin-entered scores unless those fields are included in the seed.

### Staging test data

For demos/smoke tests only (marked `isTestData: true`):

```bash
npm --prefix functions run test:brackets:dry-run -- --count=25 --seed=demo1
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:brackets -- --count=25 --seed=demo1
GCLOUD_PROJECT=testing-fe25d npm --prefix functions run test:reset -- --seed=demo1
```

---

## Tests

```bash
flutter test                    # Flutter unit + widget tests
npm --prefix functions test     # Cloud Functions tests
flutter analyze                 # Static analysis
```

### Staging browser smoke tests (Playwright)

```bash
npm --prefix e2e install
npm --prefix e2e run install:browsers

E2E_ADMIN_EMAIL=rgw1985@hotmail.com \
E2E_ADMIN_PASSWORD='your-password' \
npm --prefix e2e run test:staging
```

Default URL: `https://testing-fe25d.web.app`

---

## Pre-commit / pre-deploy checklist

```bash
flutter analyze
flutter test
npm --prefix functions test
```

---

## Notes

- Keep API tokens and admin passwords out of client code and git.
- Use dry-run flags before writing staging data to production.
- Admin manual entry remains the fallback if sync fails.
- User-facing copy says **"game"**; internal models may still use `Fixture` and
  `/fixtures`.
