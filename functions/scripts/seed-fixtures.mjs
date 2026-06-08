import { spawnSync } from 'node:child_process';
import process from 'node:process';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
const dryRun = process.argv.includes('--dry-run');

const dart = spawnSync('dart', ['run', 'tool/write_fixture_seed_json.dart'], {
  cwd: new URL('../..', import.meta.url),
  encoding: 'utf8',
});

if (dart.status !== 0) {
  console.error(dart.stderr || dart.stdout);
  process.exit(dart.status ?? 1);
}

const fixtures = JSON.parse(dart.stdout);

if (dryRun) {
  console.log(`Dry run: ${fixtures.length} fixture documents are ready.`);
  console.log(`First fixture: ${fixtures[0].id} ${fixtures[0].roundLabel}`);
  console.log(
    `Last fixture: ${fixtures.at(-1).id} ${fixtures.at(-1).roundLabel}`,
  );
  process.exit(0);
}

if (!projectId && !process.env.FIRESTORE_EMULATOR_HOST) {
  console.error(
    'Set GCLOUD_PROJECT/FIREBASE_PROJECT_ID, or run against the Firestore emulator.',
  );
  process.exit(1);
}

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const firestore = getFirestore();

for (let index = 0; index < fixtures.length; index += 450) {
  const batch = firestore.batch();
  for (const fixture of fixtures.slice(index, index + 450)) {
    const { id, ...data } = fixture;
    batch.set(firestore.doc(`fixtures/${id}`), stripNullValues(data), {
      merge: true,
    });
  }
  await batch.commit();
}

console.log(`Seeded ${fixtures.length} fixture documents into /fixtures.`);

function stripNullValues(value) {
  return Object.fromEntries(
    Object.entries(value).filter(([, entryValue]) => entryValue !== null),
  );
}
