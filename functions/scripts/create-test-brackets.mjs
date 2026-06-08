import {
  commitInChunks,
  defaultBracketCount,
  defaultTestRunId,
  initializeFirestore,
  makeRandomBracket,
  makeRng,
  parseArgs,
  testUserId,
  testUsername,
} from './test-data-utils.mjs';

const args = parseArgs();
const dryRun = args['dry-run'] === true;
const count = Number.parseInt(args.count ?? `${defaultBracketCount}`, 10);
const testRunId = `${args.seed ?? args['test-run-id'] ?? defaultTestRunId}`;
const rng = makeRng(`brackets:${testRunId}`);
const now = new Date();

if (!Number.isInteger(count) || count < 1 || count > 250) {
  throw new Error('Use --count with a value from 1 to 250.');
}

const users = [];
const usernames = [];
const brackets = [];

for (let index = 1; index <= count; index++) {
  const userId = testUserId(testRunId, index);
  const username = testUsername(testRunId, index);
  users.push([
    userId,
    {
      username,
      email: null,
      createdAt: now.toISOString(),
      linkedProviders: [],
      isHidden: false,
      isTestData: true,
      testRunId,
    },
  ]);
  usernames.push([
    username.toLowerCase(),
    {
      userId,
      authEmail: `${userId}@test.local`,
      createdAt: now.toISOString(),
      isTestData: true,
      testRunId,
    },
  ]);
  brackets.push([
    userId,
    {
      ...makeRandomBracket({ userId, rng, now }),
      testRunId,
    },
  ]);
}

if (dryRun) {
  console.log(`Dry run: would create ${count} test users and submitted brackets.`);
  console.log(`Test run id: ${testRunId}`);
  console.log(`First user: ${users[0][0]} (${users[0][1].username})`);
  process.exit(0);
}

const firestore = initializeFirestore();
const writes = [
  ...users.map(([id, data]) => (batch) => batch.set(firestore.doc(`users/${id}`), data, { merge: true })),
  ...usernames.map(([id, data]) => (batch) => batch.set(firestore.doc(`usernames/${id}`), data, { merge: true })),
  ...brackets.map(([id, data]) =>
    (batch) => batch.set(firestore.doc(`globalContest/current/brackets/${id}`), data, { merge: true }),
  ),
];

await commitInChunks(firestore, writes);
console.log(`Created ${count} test users and submitted brackets for test run ${testRunId}.`);
