import {FieldValue, Firestore} from "firebase-admin/firestore";
import {
  buildCountryMapsFromFirestore,
  enrichCountryMapsFromApiTeams,
} from "./country-api-mapper";
import {
  fetchWorldCupMatches,
  fetchWorldCupTeams,
  toRemoteFixture,
} from "./football-data-client";
import {
  buildFixtureUpdates,
  FixtureUpdate,
  LocalFixtureDoc,
  runnerUpScore,
  shouldRunMatchWindowSync,
  winnerScore,
} from "./sync-helpers";

export type SyncSource = "scheduled" | "manual";

export type SyncSummary = {
  fixturesUpdated: number;
  skippedAdmin: number;
  skippedUnmatched: number;
  skippedUnchanged: number;
  knockoutResultsUpdated: number;
  apiFixturesReceived: number;
  localFixturesLoaded: number;
  countriesWithApiId: number;
  countriesEnrichedFromApi: number;
  source: SyncSource;
};

const OFFICIAL_RESULTS_PATH = "globalContest/current/officialResults/current";

export async function runWorldCupSync(
  db: Firestore,
  token: string,
  source: SyncSource,
): Promise<SyncSummary> {
  const countriesSnap = await db.collection("countries").get();
  const countries = countriesSnap.docs.map((doc) => ({
    id: doc.id,
    name: doc.get("name") as string | undefined,
    abbreviation: doc.get("abbreviation") as string | undefined,
  }));
  const countryMaps = buildCountryMapsFromFirestore(countriesSnap.docs);
  const apiTeams = await fetchWorldCupTeams(token);
  const countriesEnrichedFromApi = enrichCountryMapsFromApiTeams(
    countryMaps,
    countries,
    apiTeams,
  );

  const localFixtures = await loadLocalFixtures(db);
  const apiMatches = await fetchWorldCupMatches(token);
  const remoteFixtures = apiMatches.map(toRemoteFixture);
  const buildResult = buildFixtureUpdates(
    remoteFixtures,
    localFixtures,
    countryMaps.countryIdByApiTeamId,
    countryMaps.apiTeamIdByCountryId,
  );

  const fixtureDataById = new Map(
    localFixtures.map((fixture) => [fixture.id, fixture]),
  );

  let knockoutResultsUpdated = 0;
  if (buildResult.updates.length > 0) {
    await commitFixtureUpdates(db, buildResult.updates);
    knockoutResultsUpdated = await applyKnockoutOfficialResults(
      db,
      buildResult.updates,
      fixtureDataById,
    );
  }

  return {
    fixturesUpdated: buildResult.updates.length,
    skippedAdmin: buildResult.skippedAdmin,
    skippedUnmatched: buildResult.skippedUnmatched,
    skippedUnchanged: buildResult.skippedUnchanged,
    knockoutResultsUpdated,
    apiFixturesReceived: remoteFixtures.length,
    localFixturesLoaded: localFixtures.length,
    countriesWithApiId: countryMaps.apiTeamIdByCountryId.size,
    countriesEnrichedFromApi,
    source,
  };
}

export async function shouldRunScheduledMatchWindowSync(
  db: Firestore,
  now = Date.now(),
): Promise<boolean> {
  const fixtures = await loadLocalFixtures(db);
  return shouldRunMatchWindowSync(fixtures, now);
}

export async function writeSyncState(
  db: Firestore,
  summary: SyncSummary,
  error: string | null,
): Promise<void> {
  await db.doc("syncState/current").set(
    {
      lastSyncAt: FieldValue.serverTimestamp(),
      lastError: error,
      fixturesUpdated: summary.fixturesUpdated,
      skippedAdmin: summary.skippedAdmin,
      skippedUnmatched: summary.skippedUnmatched,
      skippedUnchanged: summary.skippedUnchanged,
      knockoutResultsUpdated: summary.knockoutResultsUpdated,
      apiFixturesReceived: summary.apiFixturesReceived,
      localFixturesLoaded: summary.localFixturesLoaded,
      countriesWithApiId: summary.countriesWithApiId,
      countriesEnrichedFromApi: summary.countriesEnrichedFromApi,
      source: summary.source,
    },
    {merge: true},
  );
}

async function loadLocalFixtures(db: Firestore): Promise<LocalFixtureDoc[]> {
  const snapshot = await db.collection("fixtures").get();
  return snapshot.docs
    .filter((doc) => doc.id.startsWith("m"))
    .map((doc) => ({id: doc.id, ...doc.data()} as LocalFixtureDoc));
}

async function commitFixtureUpdates(
  db: Firestore,
  updates: FixtureUpdate[],
): Promise<void> {
  const chunkSize = 450;
  for (let index = 0; index < updates.length; index += chunkSize) {
    const batch = db.batch();
    for (const update of updates.slice(index, index + chunkSize)) {
      batch.set(
        db.collection("fixtures").doc(update.docId),
        {
          status: update.status,
          homeScore: update.homeScore,
          awayScore: update.awayScore,
          winnerCountryId: update.winnerCountryId,
          syncedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }
    await batch.commit();
  }
}

async function applyKnockoutOfficialResults(
  db: Firestore,
  updates: FixtureUpdate[],
  fixtureDataById: Map<string, LocalFixtureDoc>,
): Promise<number> {
  const knockoutUpdates = updates.filter(
    (update) =>
      update.stage &&
      update.stage !== "group" &&
      update.status === "finished" &&
      update.winnerCountryId,
  );
  if (knockoutUpdates.length === 0) {
    return 0;
  }

  const officialRef = db.doc(OFFICIAL_RESULTS_PATH);
  const officialSnap = await officialRef.get();
  const official = officialSnap.data() ?? {};
  const winners = {
    ...(official.knockoutWinnersBySlot as Record<string, string> | undefined),
  };

  let finalChampionScore = official.finalChampionScore as number | null | undefined;
  let finalRunnerUpScore = official.finalRunnerUpScore as number | null | undefined;
  let changed = false;

  for (const update of knockoutUpdates) {
    const local = fixtureDataById.get(update.docId);
    winners[update.docId] = update.winnerCountryId!;
    changed = true;

    if (update.stage === "finalMatch") {
      finalChampionScore = winnerScore(
        update.homeScore,
        update.awayScore,
        update.winnerCountryId,
        local?.homeCountryId,
        local?.awayCountryId,
      );
      finalRunnerUpScore = runnerUpScore(
        update.homeScore,
        update.awayScore,
        update.winnerCountryId,
        local?.homeCountryId,
        local?.awayCountryId,
      );
    }
  }

  if (!changed) {
    return 0;
  }

  await officialRef.set(
    {
      knockoutWinnersBySlot: winners,
      finalChampionScore: finalChampionScore ?? null,
      finalRunnerUpScore: finalRunnerUpScore ?? null,
      updatedAt: new Date().toISOString(),
      updatedBy: "football-data-sync",
    },
    {merge: true},
  );
  return knockoutUpdates.length;
}
