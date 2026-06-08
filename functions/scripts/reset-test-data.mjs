import {
  commitInChunks,
  defaultTestRunId,
  initializeFirestore,
  loadSeedFixtures,
  parseArgs,
  queryAll,
} from './test-data-utils.mjs';

const args = parseArgs();
const dryRun = args['dry-run'] === true;
const testRunId = `${args.seed ?? args['test-run-id'] ?? defaultTestRunId}`;
const now = new Date();

const firestore = dryRun ? null : initializeFirestore();

if (dryRun) {
  console.log(`Dry run: would reset generated test data for test run ${testRunId}.`);
  console.log('Would restore 104 seeded fixture documents, clear standings, and clear official results.');
  process.exit(0);
}

const [
  userDocs,
  usernameDocs,
  bracketDocs,
  leaderboardDocs,
  auditDocs,
  standingDocs,
] = await Promise.all([
  queryAll(firestore.collection('users').where('isTestData', '==', true).where('testRunId', '==', testRunId)),
  queryAll(firestore.collection('usernames').where('isTestData', '==', true).where('testRunId', '==', testRunId)),
  queryAll(
    firestore
      .collection('globalContest/current/brackets')
      .where('isTestData', '==', true)
      .where('testRunId', '==', testRunId),
  ),
  queryAll(
    firestore
      .collection('leaderboards/global/entries')
      .where('isTestData', '==', true)
      .where('testRunId', '==', testRunId),
  ),
  queryAll(firestore.collection('adminAuditLogs').where('isTestData', '==', true).where('testRunId', '==', testRunId)),
  queryAll(firestore.collection('standings')),
]);

for (const doc of userDocs) {
  await firestore.recursiveDelete(doc.ref);
}

const seededFixtures = loadSeedFixtures();
const writes = [
  ...seededFixtures.map(({ id, ...fixture }) => (batch) => batch.set(firestore.doc(`fixtures/${id}`), fixture)),
  ...usernameDocs.map((doc) => (batch) => batch.delete(doc.ref)),
  ...bracketDocs.map((doc) => (batch) => batch.delete(doc.ref)),
  ...leaderboardDocs.map((doc) => (batch) => batch.delete(doc.ref)),
  ...auditDocs.map((doc) => (batch) => batch.delete(doc.ref)),
  ...standingDocs.map((doc) => (batch) => batch.delete(doc.ref)),
  (batch) =>
    batch.set(firestore.doc('globalContest/current/officialResults/current'), {
      advancingCountryIds: [],
      knockoutWinnersBySlot: {},
      finalChampionScore: null,
      finalRunnerUpScore: null,
      groupPlacements: null,
      updatedAt: now.toISOString(),
      updatedBy: 'test-data-reset',
      leaderboardUpdatedAt: null,
    }),
];

await commitInChunks(firestore, writes);
console.log(
  `Reset test run ${testRunId}: deleted ${userDocs.length} users, ${bracketDocs.length} brackets, ${leaderboardDocs.length} leaderboard entries, restored ${seededFixtures.length} fixtures, and cleared ${standingDocs.length} standings.`,
);
