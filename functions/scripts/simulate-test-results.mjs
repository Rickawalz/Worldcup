import {
  adminScriptUser,
  calculateStandings,
  commitInChunks,
  defaultTestRunId,
  groupIds,
  initializeFirestore,
  knockoutSlots,
  loadSeedFixtures,
  makeRng,
  officialPlacementsFromStandings,
  parseArgs,
  pick,
  queryAll,
  scoreBrackets,
  slotParticipants,
  stripNullValues,
} from './test-data-utils.mjs';

const args = parseArgs();
const dryRun = args['dry-run'] === true;
const testRunId = `${args.seed ?? args['test-run-id'] ?? defaultTestRunId}`;
const rng = makeRng(`results:${testRunId}`);
const now = new Date();

const fixtures = loadSeedFixtures().map(({ id, ...fixture }) => ({ id, ...fixture }));
simulateGroupResults(fixtures, rng);
const standings = calculateStandings(fixtures, now);
const placements = officialPlacementsFromStandings(standings);
const knockoutWinnersBySlot = simulateKnockouts(fixtures, placements, rng);
const finalFixture = fixtures.find((fixture) => fixture.id === 'm104');

const officialResults = {
  advancingCountryIds: placements.advancingCountryIds,
  knockoutWinnersBySlot,
  finalChampionScore: winnerScore(finalFixture),
  finalRunnerUpScore: runnerUpScore(finalFixture),
  groupPlacements: {
    groupPicks: placements.groupPicks,
    bestThirdGroupIds: placements.bestThirdGroupIds,
  },
  updatedAt: now.toISOString(),
  updatedBy: adminScriptUser.id,
  leaderboardUpdatedAt: now.toISOString(),
};

if (dryRun) {
  console.log(`Dry run: would finish ${fixtures.length} fixtures and recalculate standings/leaderboard.`);
  console.log(`Test run id: ${testRunId}`);
  console.log(`Champion: ${knockoutWinnersBySlot.m104}`);
  process.exit(0);
}

const firestore = initializeFirestore();
const { usersById, bracketsByUserId } = await loadGeneratedUsersAndBrackets(firestore, testRunId);
const config = await firestore.doc('globalContest/current/config/current').get();
const pointsPerCorrectPick = Number(config.data()?.pointsPerCorrectPick ?? 1);
const { entries, updatedBrackets } = scoreBrackets({
  brackets: bracketsByUserId,
  usersById,
  officialResults,
  pointsPerCorrectPick,
  now,
});

const writes = [
  ...fixtures.map((fixture) => (batch) =>
    batch.set(firestore.doc(`fixtures/${fixture.id}`), stripNullValues(fixture), { merge: true }),
  ),
  ...standings.map((standing) => (batch) =>
    batch.set(firestore.doc(`standings/${standing.groupId}`), standing, { merge: true }),
  ),
  (batch) =>
    batch.set(firestore.doc('globalContest/current/officialResults/current'), officialResults, {
      merge: true,
    }),
  ...updatedBrackets.map(([userId, bracket]) => (batch) =>
    batch.set(firestore.doc(`globalContest/current/brackets/${userId}`), bracket, { merge: true }),
  ),
  ...entries.map((entry) => (batch) =>
    batch.set(firestore.doc(`leaderboards/global/entries/${entry.userId}`), entry, { merge: true }),
  ),
  (batch) =>
    batch.set(firestore.collection('adminAuditLogs').doc(), {
      operationType: 'leaderboardRecalculation',
      before: null,
      after: {
        testRunId,
        fixturesFinished: fixtures.length,
        leaderboardEntries: entries.length,
      },
      adminUserId: adminScriptUser.id,
      adminEmail: adminScriptUser.email,
      createdAt: now.toISOString(),
      note: 'Generated staging test results',
      isTestData: true,
      testRunId,
    }),
];

await commitInChunks(firestore, writes);
console.log(
  `Simulated ${fixtures.length} fixtures, ${standings.length} standings, and ${entries.length} leaderboard entries for ${testRunId}.`,
);

function simulateGroupResults(fixtures, rng) {
  for (const fixture of fixtures.filter((item) => item.stage === 'group')) {
    const homeScore = Math.floor(rng() * 5);
    const awayScore = Math.floor(rng() * 5);
    Object.assign(fixture, {
      homeScore,
      awayScore,
      winnerCountryId:
        homeScore === awayScore
          ? null
          : homeScore > awayScore
            ? fixture.homeCountryId
            : fixture.awayCountryId,
      status: 'finished',
      updatedAt: now.toISOString(),
      updatedBy: adminScriptUser.id,
    });
  }
}

function simulateKnockouts(fixtures, placements, rng) {
  const winnersBySlot = new Map();
  const groupPicks = placements.groupPicks;
  const bestThirdGroupIds = placements.bestThirdGroupIds;
  const winners = {};
  for (const slot of knockoutSlots) {
    const fixture = fixtures.find((item) => item.id === slot.id);
    if (!fixture) continue;
    const participants = slotParticipants(slot, groupPicks, bestThirdGroupIds, winnersBySlot);
    const [homeCountryId, awayCountryId] = participants;
    const homeWins = rng() >= 0.5;
    const score = knockoutScore(rng, homeWins);
    const winnerCountryId = homeWins ? homeCountryId : awayCountryId;
    Object.assign(fixture, {
      homeCountryId,
      awayCountryId,
      homeScore: score.homeScore,
      awayScore: score.awayScore,
      winnerCountryId,
      status: 'finished',
      updatedAt: now.toISOString(),
      updatedBy: adminScriptUser.id,
    });
    winnersBySlot.set(slot.id, winnerCountryId);
    winners[slot.id] = winnerCountryId;
  }

  const thirdPlace = fixtures.find((item) => item.id === 'm103');
  if (thirdPlace) {
    const semifinalLosers = [
      loser(fixtures.find((item) => item.id === 'm101')),
      loser(fixtures.find((item) => item.id === 'm102')),
    ].filter(Boolean);
    if (semifinalLosers.length === 2) {
      const homeWins = rng() >= 0.5;
      const score = knockoutScore(rng, homeWins);
      Object.assign(thirdPlace, {
        homeCountryId: semifinalLosers[0],
        awayCountryId: semifinalLosers[1],
        homeScore: score.homeScore,
        awayScore: score.awayScore,
        winnerCountryId: homeWins ? semifinalLosers[0] : semifinalLosers[1],
        status: 'finished',
        updatedAt: now.toISOString(),
        updatedBy: adminScriptUser.id,
      });
    }
  }
  return winners;
}

function knockoutScore(rng, homeWins) {
  const loserGoals = Math.floor(rng() * 3);
  const winnerGoals = loserGoals + 1 + Math.floor(rng() * 3);
  return homeWins
    ? { homeScore: winnerGoals, awayScore: loserGoals }
    : { homeScore: loserGoals, awayScore: winnerGoals };
}

function loser(fixture) {
  if (!fixture || !fixture.winnerCountryId) return null;
  return fixture.homeCountryId === fixture.winnerCountryId ? fixture.awayCountryId : fixture.homeCountryId;
}

function winnerScore(fixture) {
  if (!fixture || !fixture.winnerCountryId) return null;
  return fixture.homeCountryId === fixture.winnerCountryId ? fixture.homeScore : fixture.awayScore;
}

function runnerUpScore(fixture) {
  if (!fixture || !fixture.winnerCountryId) return null;
  return fixture.homeCountryId === fixture.winnerCountryId ? fixture.awayScore : fixture.homeScore;
}

async function loadGeneratedUsersAndBrackets(firestore, testRunId) {
  const userDocs = await queryAll(
    firestore.collection('users').where('isTestData', '==', true).where('testRunId', '==', testRunId),
  );
  const usersById = new Map(userDocs.map((doc) => [doc.id, doc.data()]));
  const bracketDocs = await queryAll(
    firestore
      .collection('globalContest/current/brackets')
      .where('isTestData', '==', true)
      .where('testRunId', '==', testRunId),
  );
  const bracketsByUserId = new Map(bracketDocs.map((doc) => [doc.id, doc.data()]));
  return { usersById, bracketsByUserId };
}
