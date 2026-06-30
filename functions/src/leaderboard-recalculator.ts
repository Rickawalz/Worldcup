import {Firestore, FieldValue} from "firebase-admin/firestore";
import {
  advancingCountryIds,
  OfficialGroupPlacements,
  officialPlacementsForScoring,
  officialPlacementsFromStandings,
  shouldAutoUpdateGroupPlacements,
} from "./group-placements";
import {OfficialResultsRecord, scoreBracket} from "./scoring";
import {calculateStandings, FixtureRecord, GroupStanding} from "./standings-calculator";

const OFFICIAL_RESULTS_PATH = "globalContest/current/officialResults/current";
const BRACKETS_PATH = "globalContest/current/brackets";

export type LeaderboardRecalculationSummary = {
  entriesUpdated: number;
  bracketsScored: number;
  groupPlacementsUpdated: boolean;
};

type UserRecord = {
  username: string;
  isHidden?: boolean;
};

export async function reconcileTournamentState(
  db: Firestore,
  updatedBy = "leaderboard-recalc",
): Promise<LeaderboardRecalculationSummary> {
  const [fixturesSnap, standingsSnap, officialSnap] = await Promise.all([
    db.collection("fixtures").get(),
    db.collection("standings").get(),
    db.doc(OFFICIAL_RESULTS_PATH).get(),
  ]);

  const fixtures: FixtureRecord[] = fixturesSnap.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  })) as FixtureRecord[];

  const existingStandings = standingsSnap.docs.map((doc) => ({
    groupId: doc.id,
    overrideOrderCountryIds: doc.get("overrideOrderCountryIds") as
      | string[]
      | undefined,
  }));

  const now = new Date().toISOString();
  const calculatedStandings = calculateStandings(
    fixtures,
    existingStandings,
    now,
    updatedBy,
  );

  const standingsBatch = db.batch();
  for (const standing of calculatedStandings) {
    standingsBatch.set(db.collection("standings").doc(standing.groupId), {
      groupId: standing.groupId,
      rows: standing.rows,
      overrideOrderCountryIds: standing.overrideOrderCountryIds,
      updatedAt: standing.updatedAt,
      updatedBy: standing.updatedBy,
    });
  }
  await standingsBatch.commit();

  const official = officialSnap.data() ?? {};
  let groupPlacementsUpdated = false;
  const storedPlacements = parseGroupPlacements(official.groupPlacements);
  const placementsForScoring = officialPlacementsForScoring(
    calculatedStandings,
    storedPlacements,
  );
  let officialResults: OfficialResultsRecord = {
    groupPlacements: placementsForScoring,
    knockoutWinnersBySlot:
      (official.knockoutWinnersBySlot as Record<string, string> | undefined) ??
      {},
    finalChampionScore: official.finalChampionScore as number | null | undefined,
    finalRunnerUpScore: official.finalRunnerUpScore as number | null | undefined,
  };

  const fullPlacements = officialPlacementsFromStandings(calculatedStandings);
  if (
    fullPlacements != null &&
    shouldAutoUpdateGroupPlacements(official.updatedBy as string | undefined)
  ) {
    officialResults = {
      ...officialResults,
      groupPlacements: fullPlacements,
    };
    await db.doc(OFFICIAL_RESULTS_PATH).set(
      {
        groupPlacements: fullPlacements,
        advancingCountryIds: advancingCountryIds(fullPlacements),
        updatedAt: now,
        updatedBy: updatedBy,
      },
      {merge: true},
    );
    groupPlacementsUpdated = true;
  }

  const bracketsSnap = await db.collection(BRACKETS_PATH).get();
  const usersById = await loadUsersById(db, bracketsSnap.docs.map((doc) => doc.id));

  const scoredEntries: Array<{
    userId: string;
    username: string;
    score: number;
    groupScore: number;
    knockoutScore: number;
    tiebreakerDistance: number;
    updatedAt: string;
  }> = [];

  const bracketBatch = db.batch();
  let bracketsScored = 0;

  for (const doc of bracketsSnap.docs) {
    const data = doc.data();
    if (data.status !== "submitted") {
      continue;
    }

    const breakdown = scoreBracket(data, officialResults);
    bracketsScored += 1;
    bracketBatch.set(
      doc.ref,
      {
        totalScore: breakdown.totalScore,
        groupScore: breakdown.groupScore,
        knockoutScore: breakdown.knockoutScore,
        tiebreakerDistance: breakdown.tiebreakerDistance,
        updatedAt: now,
      },
      {merge: true},
    );

    const user = usersById.get(doc.id);
    if (user != null && user.isHidden !== true) {
      scoredEntries.push({
        userId: doc.id,
        username: user.username,
        score: breakdown.totalScore,
        groupScore: breakdown.groupScore,
        knockoutScore: breakdown.knockoutScore,
        tiebreakerDistance: breakdown.tiebreakerDistance,
        updatedAt: now,
      });
    }
  }

  await bracketBatch.commit();

  scoredEntries.sort((a, b) => {
    if (b.score !== a.score) {
      return b.score - a.score;
    }
    if (a.tiebreakerDistance !== b.tiebreakerDistance) {
      return a.tiebreakerDistance - b.tiebreakerDistance;
    }
    return a.username.toLowerCase().localeCompare(b.username.toLowerCase());
  });

  const leaderboardBatch = db.batch();
  scoredEntries.forEach((entry, index) => {
    leaderboardBatch.set(db.doc(`leaderboards/global/entries/${entry.userId}`), {
      userId: entry.userId,
      username: entry.username,
      score: entry.score,
      groupScore: entry.groupScore,
      knockoutScore: entry.knockoutScore,
      tiebreakerDistance: entry.tiebreakerDistance,
      rank: index + 1,
      updatedAt: now,
    });
  });
  await leaderboardBatch.commit();

  await db.doc(OFFICIAL_RESULTS_PATH).set(
    {
      leaderboardUpdatedAt: now,
    },
    {merge: true},
  );

  return {
    entriesUpdated: scoredEntries.length,
    bracketsScored,
    groupPlacementsUpdated,
  };
}

async function loadUsersById(
  db: Firestore,
  userIds: string[],
): Promise<Map<string, UserRecord>> {
  const usersById = new Map<string, UserRecord>();
  const uniqueIds = [...new Set(userIds)];
  const chunkSize = 30;

  for (let index = 0; index < uniqueIds.length; index += chunkSize) {
    const chunk = uniqueIds.slice(index, index + chunkSize);
    const snapshot = await db
      .collection("users")
      .where("__name__", "in", chunk)
      .get();
    for (const doc of snapshot.docs) {
      usersById.set(doc.id, {
        username: (doc.get("username") as string | undefined) ?? doc.id,
        isHidden: doc.get("isHidden") as boolean | undefined,
      });
    }
  }

  return usersById;
}

export function officialPlacementsFromCalculatedStandings(
  standings: GroupStanding[],
) {
  return officialPlacementsFromStandings(standings);
}

function parseGroupPlacements(
  raw: unknown,
): OfficialGroupPlacements | null {
  if (raw == null || typeof raw !== "object") {
    return null;
  }
  const map = raw as Record<string, unknown>;
  const groupPicksRaw = map.groupPicks;
  const bestThirdGroupIdsRaw = map.bestThirdGroupIds;
  if (!Array.isArray(groupPicksRaw) || !Array.isArray(bestThirdGroupIdsRaw)) {
    return null;
  }
  return {
    groupPicks: groupPicksRaw
      .filter((item): item is Record<string, unknown> => item != null && typeof item === "object")
      .map((item) => ({
        groupId: String(item.groupId ?? ""),
        firstCountryId: String(item.firstCountryId ?? ""),
        secondCountryId: String(item.secondCountryId ?? ""),
        thirdCountryId: String(item.thirdCountryId ?? ""),
      })),
    bestThirdGroupIds: bestThirdGroupIdsRaw.map((groupId) => String(groupId)),
  };
}
