import { spawnSync } from 'node:child_process';
import process from 'node:process';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
const dryRun = process.argv.includes('--dry-run');

const dart = spawnSync('dart', ['run', 'tool/write_country_seed_json.dart'], {
  cwd: new URL('../..', import.meta.url),
  encoding: 'utf8',
});

if (dart.status !== 0) {
  console.error(dart.stderr || dart.stdout);
  process.exit(dart.status ?? 1);
}

const countries = JSON.parse(dart.stdout);

if (dryRun) {
  console.log(`Dry run: ${countries.length} country documents are ready.`);
  console.log(`First country: ${countries[0].id} api=${countries[0].apiFootballTeamId}`);
  process.exit(0);
}

if (!projectId && !process.env.FIRESTORE_EMULATOR_HOST) {
  console.error(
    'Set GCLOUD_PROJECT/FIREBASE_PROJECT_ID, or run against the Firestore emulator.',
  );
  process.exit(1);
}

if (!process.env.GOOGLE_CLOUD_QUOTA_PROJECT && projectId) {
  process.env.GOOGLE_CLOUD_QUOTA_PROJECT = projectId;
}

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const firestore = getFirestore();
const batch = firestore.batch();
for (const country of countries) {
  const { id, ...data } = country;
  batch.set(firestore.doc(`countries/${id}`), data, { merge: true });
}
await batch.commit();

console.log(`Seeded ${countries.length} country documents into /countries.`);
