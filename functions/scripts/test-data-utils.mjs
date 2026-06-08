import { spawnSync } from 'node:child_process';
import crypto from 'node:crypto';
import process from 'node:process';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

export const testDataPrefix = 'wc_test';
export const defaultTestRunId = 'demo1';
export const defaultBracketCount = 25;
export const adminScriptUser = {
  id: 'test-data-script',
  email: 'test-data-script@local',
};

export const groupIds = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];

export const groupCountryIds = {
  A: ['mexico', 'south_africa', 'south_korea', 'czech_republic'],
  B: ['canada', 'bosnia_herzegovina', 'qatar', 'switzerland'],
  C: ['brazil', 'morocco', 'haiti', 'scotland'],
  D: ['usa', 'paraguay', 'australia', 'turkey'],
  E: ['germany', 'curacao', 'cote_divoire', 'ecuador'],
  F: ['netherlands', 'japan', 'sweden', 'tunisia'],
  G: ['belgium', 'egypt', 'iran', 'new_zealand'],
  H: ['spain', 'cabo_verde', 'saudi_arabia', 'uruguay'],
  I: ['france', 'senegal', 'iraq', 'norway'],
  J: ['argentina', 'algeria', 'austria', 'jordan'],
  K: ['portugal', 'congo_dr', 'uzbekistan', 'colombia'],
  L: ['england', 'croatia', 'ghana', 'panama'],
};

export const knockoutSlots = [
  ['m73', 'roundOf32', '2A', '2B'],
  ['m76', 'roundOf32', '1C', '2F'],
  ['m74', 'roundOf32', '1E', '3rd A/B/C/D/F'],
  ['m75', 'roundOf32', '1F', '2C'],
  ['m78', 'roundOf32', '2E', '2I'],
  ['m77', 'roundOf32', '1I', '3rd C/D/F/G/H'],
  ['m79', 'roundOf32', '1A', '3rd C/E/F/H/I'],
  ['m80', 'roundOf32', '1L', '3rd E/H/I/J/K'],
  ['m82', 'roundOf32', '1G', '3rd A/E/H/I/J'],
  ['m81', 'roundOf32', '1D', '3rd B/E/F/I/J'],
  ['m84', 'roundOf32', '1H', '2J'],
  ['m83', 'roundOf32', '2K', '2L'],
  ['m85', 'roundOf32', '1B', '3rd E/F/G/I/J'],
  ['m88', 'roundOf32', '2D', '2G'],
  ['m86', 'roundOf32', '1J', '2H'],
  ['m87', 'roundOf32', '1K', '3rd D/E/I/J/L'],
  ['m89', 'roundOf16', 'W74', 'W77'],
  ['m90', 'roundOf16', 'W73', 'W75'],
  ['m91', 'roundOf16', 'W76', 'W78'],
  ['m92', 'roundOf16', 'W79', 'W80'],
  ['m93', 'roundOf16', 'W83', 'W84'],
  ['m94', 'roundOf16', 'W81', 'W82'],
  ['m95', 'roundOf16', 'W86', 'W88'],
  ['m96', 'roundOf16', 'W85', 'W87'],
  ['m97', 'quarterfinal', 'W89', 'W90'],
  ['m98', 'quarterfinal', 'W93', 'W94'],
  ['m99', 'quarterfinal', 'W91', 'W92'],
  ['m100', 'quarterfinal', 'W95', 'W96'],
  ['m101', 'semifinal', 'W97', 'W98'],
  ['m102', 'semifinal', 'W99', 'W100'],
  ['m104', 'finalMatch', 'W101', 'W102'],
].map(([id, stage, sourceA, sourceB]) => ({ id, stage, sourceA, sourceB }));

export function parseArgs(argv = process.argv.slice(2)) {
  const args = {};
  for (const arg of argv) {
    if (!arg.startsWith('--')) continue;
    const [key, rawValue] = arg.slice(2).split('=');
    args[key] = rawValue ?? true;
  }
  return args;
}

export function assertSafeTarget() {
  const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
  if (process.env.FIRESTORE_EMULATOR_HOST) return projectId ?? 'emulator';
  if (projectId === 'testing-fe25d') return projectId;
  throw new Error(
    'Refusing to run test-data script outside staging/emulator. Set GCLOUD_PROJECT=testing-fe25d or FIRESTORE_EMULATOR_HOST.',
  );
}

export function initializeFirestore() {
  const projectId = assertSafeTarget();
  initializeApp({ credential: applicationDefault(), projectId });
  return getFirestore();
}

export function makeRng(seed) {
  let state = crypto.createHash('sha256').update(seed).digest().readUInt32BE(0);
  return () => {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 0x100000000;
  };
}

export function pick(rng, items) {
  return items[Math.floor(rng() * items.length)];
}

export function shuffle(rng, items) {
  const copy = [...items];
  for (let index = copy.length - 1; index > 0; index--) {
    const swapIndex = Math.floor(rng() * (index + 1));
    [copy[index], copy[swapIndex]] = [copy[swapIndex], copy[index]];
  }
  return copy;
}

export function testUserId(testRunId, index) {
  return `${testDataPrefix}_${testRunId}_${String(index).padStart(3, '0')}`;
}

export function testUsername(testRunId, index) {
  return `TestPlayer_${testRunId}_${String(index).padStart(3, '0')}`;
}

export function loadSeedFixtures() {
  const dart = spawnSync('dart', ['run', 'tool/write_fixture_seed_json.dart'], {
    cwd: new URL('../..', import.meta.url),
    encoding: 'utf8',
  });
  if (dart.status !== 0) {
    throw new Error(dart.stderr || dart.stdout);
  }
  return JSON.parse(dart.stdout);
}

export function makeRandomBracket({ userId, rng, now = new Date() }) {
  const groupPicks = groupIds.map((groupId) => {
    const ordered = shuffle(rng, groupCountryIds[groupId]);
    return {
      groupId,
      firstCountryId: ordered[0],
      secondCountryId: ordered[1],
      thirdCountryId: ordered[2],
    };
  });
  const bestThirdGroupIds = shuffle(rng, groupIds).slice(0, 8).sort();
  const picksBySlot = new Map();
  const knockoutPicks = knockoutSlots.map((slot) => {
    const participants = slotParticipants(slot, groupPicks, bestThirdGroupIds, picksBySlot);
    const winnerCountryId = pick(rng, participants);
    picksBySlot.set(slot.id, winnerCountryId);
    return { slotId: slot.id, stage: slot.stage, winnerCountryId };
  });
  return {
    status: 'submitted',
    groupPicks,
    bestThirdGroupIds,
    knockoutPicks,
    finalScoreTiebreaker: {
      championScore: 1 + Math.floor(rng() * 4),
      runnerUpScore: Math.floor(rng() * 3),
    },
    submittedAt: now.toISOString(),
    updatedAt: now.toISOString(),
    totalScore: 0,
    groupScore: 0,
    knockoutScore: 0,
    tiebreakerDistance: 0,
    isTestData: true,
    testRunId: String(userId).split(`${testDataPrefix}_`)[1]?.slice(0, -4) ?? defaultTestRunId,
  };
}

export function slotParticipants(slot, groupPicks, bestThirdGroupIds, winnersBySlot) {
  return [resolveSource(slot.sourceA), resolveSource(slot.sourceB)].filter(Boolean);

  function resolveSource(source) {
    const position = source.match(/^([123])([A-L])$/);
    if (position) {
      const pickForGroup = groupPicks.find((pick) => pick.groupId === position[2]);
      if (!pickForGroup) return null;
      if (position[1] === '1') return pickForGroup.firstCountryId;
      if (position[1] === '2') return pickForGroup.secondCountryId;
      return pickForGroup.thirdCountryId;
    }
    const third = source.match(/^3rd (.+)$/);
    if (third) {
      const groups = third[1].split('/');
      const groupId = groups.find((group) => bestThirdGroupIds.includes(group)) ?? groups[0];
      return groupPicks.find((pick) => pick.groupId === groupId)?.thirdCountryId ?? null;
    }
    const winner = source.match(/^W(\d+)$/);
    if (winner) return winnersBySlot.get(`m${winner[1]}`) ?? null;
    return null;
  }
}

export function calculateStandings(fixtures, now = new Date()) {
  return groupIds.map((groupId) => {
    const stats = new Map(
      groupCountryIds[groupId].map((countryId) => [
        countryId,
        { countryId, rank: 0, played: 0, won: 0, drawn: 0, lost: 0, goalsFor: 0, goalsAgainst: 0 },
      ]),
    );
    for (const fixture of fixtures) {
      if (
        fixture.stage !== 'group' ||
        fixture.status !== 'finished' ||
        String(fixture.roundLabel).trim().toUpperCase() !== `GROUP ${groupId}` ||
        fixture.homeScore === null ||
        fixture.homeScore === undefined ||
        fixture.awayScore === null ||
        fixture.awayScore === undefined
      ) {
        continue;
      }
      applyResult(stats.get(fixture.homeCountryId), fixture.homeScore, fixture.awayScore);
      applyResult(stats.get(fixture.awayCountryId), fixture.awayScore, fixture.homeScore);
    }
    const rows = [...stats.values()]
      .map((row) => ({ ...row, goalDifference: row.goalsFor - row.goalsAgainst, points: row.won * 3 + row.drawn }))
      .sort((a, b) => b.points - a.points || b.goalDifference - a.goalDifference || b.goalsFor - a.goalsFor || a.countryId.localeCompare(b.countryId))
      .map((row, index) => ({ ...row, rank: index + 1 }));
    return {
      groupId,
      rows,
      overrideOrderCountryIds: [],
      updatedAt: now.toISOString(),
      updatedBy: adminScriptUser.id,
    };
  });
}

function applyResult(row, goalsFor, goalsAgainst) {
  if (!row) return;
  row.played++;
  row.goalsFor += goalsFor;
  row.goalsAgainst += goalsAgainst;
  if (goalsFor > goalsAgainst) row.won++;
  else if (goalsFor < goalsAgainst) row.lost++;
  else row.drawn++;
}

export function officialPlacementsFromStandings(standings) {
  const thirdRows = [];
  const groupPicks = standings.map((standing) => {
    const rows = standing.rows;
    thirdRows.push({ groupId: standing.groupId, ...rows[2] });
    return {
      groupId: standing.groupId,
      firstCountryId: rows[0].countryId,
      secondCountryId: rows[1].countryId,
      thirdCountryId: rows[2].countryId,
    };
  });
  const bestThirdGroupIds = thirdRows
    .sort((a, b) => b.points - a.points || b.goalDifference - a.goalDifference || b.goalsFor - a.goalsFor || a.countryId.localeCompare(b.countryId))
    .slice(0, 8)
    .map((row) => row.groupId)
    .sort();
  const advancingCountryIds = new Set();
  for (const pick of groupPicks) {
    advancingCountryIds.add(pick.firstCountryId);
    advancingCountryIds.add(pick.secondCountryId);
    if (bestThirdGroupIds.includes(pick.groupId)) advancingCountryIds.add(pick.thirdCountryId);
  }
  return { groupPicks, bestThirdGroupIds, advancingCountryIds: [...advancingCountryIds].sort() };
}

export function scoreBrackets({ brackets, usersById, officialResults, pointsPerCorrectPick = 1, now = new Date() }) {
  const entries = [];
  const updatedBrackets = [];
  for (const [userId, bracket] of brackets) {
    const groupAdvancers = predictedAdvancers(bracket);
    const groupScore = groupAdvancers.filter((countryId) => officialResults.advancingCountryIds.includes(countryId)).length * pointsPerCorrectPick;
    const knockoutScore = (bracket.knockoutPicks ?? []).filter(
      (pick) => officialResults.knockoutWinnersBySlot?.[pick.slotId] === pick.winnerCountryId,
    ).length * pointsPerCorrectPick;
    const tiebreakerDistance =
      officialResults.finalChampionScore === null ||
      officialResults.finalChampionScore === undefined ||
      officialResults.finalRunnerUpScore === null ||
      officialResults.finalRunnerUpScore === undefined
        ? 0
        : Math.abs((bracket.finalScoreTiebreaker?.championScore ?? 0) - officialResults.finalChampionScore) +
          Math.abs((bracket.finalScoreTiebreaker?.runnerUpScore ?? 0) - officialResults.finalRunnerUpScore);
    const scored = {
      ...bracket,
      totalScore: groupScore + knockoutScore,
      groupScore,
      knockoutScore,
      tiebreakerDistance,
      updatedAt: now.toISOString(),
    };
    updatedBrackets.push([userId, scored]);
    const user = usersById.get(userId);
    if (user && !user.isHidden) {
      entries.push({
        userId,
        username: user.username,
        score: scored.totalScore,
        groupScore,
        knockoutScore,
        tiebreakerDistance,
        rank: 0,
        updatedAt: now.toISOString(),
        isTestData: true,
        testRunId: user.testRunId,
      });
    }
  }
  entries.sort((a, b) => b.score - a.score || a.tiebreakerDistance - b.tiebreakerDistance || a.username.toLowerCase().localeCompare(b.username.toLowerCase()));
  entries.forEach((entry, index) => {
    entry.rank = index + 1;
  });
  return { entries, updatedBrackets };
}

function predictedAdvancers(bracket) {
  const bestThirdGroups = new Set(bracket.bestThirdGroupIds ?? []);
  const advancers = new Set();
  for (const pick of bracket.groupPicks ?? []) {
    advancers.add(pick.firstCountryId);
    advancers.add(pick.secondCountryId);
    if (bestThirdGroups.has(pick.groupId) && pick.thirdCountryId) {
      advancers.add(pick.thirdCountryId);
    }
  }
  return [...advancers];
}

export async function commitInChunks(firestore, writeFns, chunkSize = 450) {
  for (let index = 0; index < writeFns.length; index += chunkSize) {
    const batch = firestore.batch();
    for (const write of writeFns.slice(index, index + chunkSize)) {
      write(batch);
    }
    await batch.commit();
  }
}

export async function queryAll(collectionRef) {
  const snapshot = await collectionRef.get();
  return snapshot.docs;
}

export function stripNullValues(value) {
  return Object.fromEntries(Object.entries(value).filter(([, entryValue]) => entryValue !== null && entryValue !== undefined));
}
