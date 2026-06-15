import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {defineSecret, defineString} from "firebase-functions/params";
import {calculateStandings, FixtureRecord} from "./standings-calculator";
import {
  runWorldCupSync,
  shouldRunScheduledMatchWindowSync,
  SyncSource,
  SyncSummary,
  writeSyncState,
} from "./sync-world-cup";

initializeApp();

const db = getFirestore();
const footballDataToken = defineSecret("FOOTBALL_DATA_TOKEN");
const adminEmail = defineString("ADMIN_EMAIL", {
  default: "rgw1985@hotmail.com",
});
const OFFICIAL_RESULTS_PATH = "globalContest/current/officialResults/current";

// Poll every 15 minutes, but only call football-data.org while a game is in its
// kickoff window so scores update soon after full time without burning the
// free tier on idle days.
export const syncWorldCupData = onSchedule(
  {
    schedule: "every 15 minutes",
    secrets: [footballDataToken],
    timeoutSeconds: 120,
  },
  async () => {
    const inMatchWindow = await shouldRunScheduledMatchWindowSync(db);
    if (!inMatchWindow) {
      return;
    }
    await executeSync("scheduled");
  },
);

export const syncWorldCupDataNow = onCall(
  {
    secrets: [footballDataToken],
    timeoutSeconds: 120,
  },
  async (request) => {
    await assertAdmin(request.auth);
    return executeSync("manual");
  },
);

export const submitAdminOverride = onCall(async (request) => {
  await assertAdmin(request.auth);
  const {targetType, targetId, values} = request.data as {
    targetType?: string;
    targetId?: string;
    values?: Record<string, unknown>;
  };
  if (!targetType || !targetId || !values) {
    throw new HttpsError("invalid-argument", "targetType, targetId, and values are required.");
  }
  const collection = targetTypeToCollection(targetType);
  await db.collection(collection).doc(targetId).set(values, {merge: true});
  await db.collection("adminOverrides").add({
    adminId: request.auth?.uid,
    targetType,
    targetId,
    values,
    createdAt: FieldValue.serverTimestamp(),
  });
});

export const recalculateLeaderboard = onCall(async (request) => {
  await assertAdmin(request.auth);
  await rebuildLeaderboard();
});

export const scoreBracketOnResult = onDocumentWritten(
  "fixtures/{fixtureId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after || after.status !== "finished") {
      return;
    }

    if (after.stage === "group") {
      await recalculateStandingsFromFixtures();
    } else if (after.winnerCountryId) {
      await updateKnockoutOfficialResults(
        event.params.fixtureId,
        after as Record<string, unknown>,
      );
    }

    await rebuildLeaderboard();
  },
);

export const sendLockReminders = onSchedule("every 24 hours", async () => {
  const config = await db.doc("globalContest/current/config/current").get();
  const lockAtRaw = config.get("lockAt");
  if (!lockAtRaw) {
    return;
  }
  const lockAt = new Date(lockAtRaw);
  const hoursUntilLock = (lockAt.getTime() - Date.now()) / 36e5;
  if (hoursUntilLock < 0 || hoursUntilLock > 48) {
    return;
  }
  const users = await db
    .collection("users")
    .where("notificationsEnabled", "==", true)
    .get();
  const tokens = users.docs.flatMap((doc) => doc.get("messagingTokens") ?? []);
  if (tokens.length === 0) {
    return;
  }
  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: "World Cup bracket lock is coming",
      body: "Finish your full bracket before the first kickoff.",
    },
  });
});

async function executeSync(source: SyncSource): Promise<SyncSummary> {
  const token = footballDataToken.value();
  if (!token) {
    throw new Error("FOOTBALL_DATA_TOKEN is not configured.");
  }

  try {
    const summary = await runWorldCupSync(db, token, source);
    await writeSyncState(db, summary, null);
    return summary;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await writeSyncState(
      db,
      {
        fixturesUpdated: 0,
        skippedAdmin: 0,
        skippedUnmatched: 0,
        skippedUnchanged: 0,
        knockoutResultsUpdated: 0,
        apiFixturesReceived: 0,
        localFixturesLoaded: 0,
        countriesWithApiId: 0,
        countriesEnrichedFromApi: 0,
        source,
      },
      message,
    );
    throw error;
  }
}

async function recalculateStandingsFromFixtures(): Promise<void> {
  const [fixturesSnap, standingsSnap] = await Promise.all([
    db.collection("fixtures").get(),
    db.collection("standings").get(),
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
  const calculated = calculateStandings(
    fixtures,
    existingStandings,
    now,
    "score-bracket-trigger",
  );

  const batch = db.batch();
  for (const standing of calculated) {
    batch.set(db.collection("standings").doc(standing.groupId), {
      groupId: standing.groupId,
      rows: standing.rows,
      overrideOrderCountryIds: standing.overrideOrderCountryIds,
      updatedAt: standing.updatedAt,
      updatedBy: standing.updatedBy,
    });
  }
  await batch.commit();
}

async function updateKnockoutOfficialResults(
  fixtureId: string,
  fixture: Record<string, unknown>,
): Promise<void> {
  const winnerCountryId = fixture.winnerCountryId as string | undefined;
  if (!winnerCountryId) {
    return;
  }

  const officialRef = db.doc(OFFICIAL_RESULTS_PATH);
  const officialSnap = await officialRef.get();
  const official = officialSnap.data() ?? {};
  const winners = {
    ...(official.knockoutWinnersBySlot as Record<string, string> | undefined),
    [fixtureId]: winnerCountryId,
  };

  const payload: Record<string, unknown> = {
    knockoutWinnersBySlot: winners,
    updatedAt: new Date().toISOString(),
    updatedBy: fixture.updatedBy ?? "score-bracket-trigger",
  };

  if (fixture.stage === "finalMatch") {
    payload.finalChampionScore = winnerScoreFromFixture(fixture);
    payload.finalRunnerUpScore = runnerUpScoreFromFixture(fixture);
  }

  await officialRef.set(payload, {merge: true});
}

function winnerScoreFromFixture(fixture: Record<string, unknown>): number | null {
  const homeScore = fixture.homeScore as number | null | undefined;
  const awayScore = fixture.awayScore as number | null | undefined;
  const winnerCountryId = fixture.winnerCountryId as string | undefined;
  const homeCountryId = fixture.homeCountryId as string | undefined;
  const awayCountryId = fixture.awayCountryId as string | undefined;
  if (
    homeScore == null ||
    awayScore == null ||
    !winnerCountryId ||
    !homeCountryId ||
    !awayCountryId
  ) {
    return null;
  }
  if (winnerCountryId === homeCountryId) return homeScore;
  if (winnerCountryId === awayCountryId) return awayScore;
  return null;
}

function runnerUpScoreFromFixture(fixture: Record<string, unknown>): number | null {
  const homeScore = fixture.homeScore as number | null | undefined;
  const awayScore = fixture.awayScore as number | null | undefined;
  const winnerCountryId = fixture.winnerCountryId as string | undefined;
  const homeCountryId = fixture.homeCountryId as string | undefined;
  const awayCountryId = fixture.awayCountryId as string | undefined;
  if (
    homeScore == null ||
    awayScore == null ||
    !winnerCountryId ||
    !homeCountryId ||
    !awayCountryId
  ) {
    return null;
  }
  if (winnerCountryId === homeCountryId) return awayScore;
  if (winnerCountryId === awayCountryId) return homeScore;
  return null;
}

async function rebuildLeaderboard(): Promise<void> {
  const brackets = await db.collection("globalContest/current/brackets").get();
  const rows = brackets.docs.map((doc) => {
    const data = doc.data();
    return {
      userId: doc.id,
      username: data.username ?? doc.id,
      score: data.totalScore ?? 0,
      tiebreakerDistance: data.tiebreakerDistance ?? 0,
    };
  });
  rows.sort((a, b) => {
    if (b.score !== a.score) {
      return b.score - a.score;
    }
    return a.tiebreakerDistance - b.tiebreakerDistance;
  });

  const batch = db.batch();
  rows.forEach((row, index) => {
    batch.set(db.doc(`leaderboards/global/entries/${row.userId}`), {
      ...row,
      rank: index + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
}

async function assertAdmin(
  auth: {uid?: string; token?: Record<string, unknown>} | undefined,
): Promise<void> {
  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in before running admin actions.");
  }

  if (auth.token?.admin === true) {
    return;
  }

  const configuredAdmin = adminEmail.value().trim().toLowerCase();
  const tokenEmail =
    typeof auth.token?.email === "string" ? auth.token.email.trim().toLowerCase() : "";
  if (tokenEmail.length > 0 && tokenEmail === configuredAdmin) {
    return;
  }

  const privateAccount = await db.doc(`users/${auth.uid}/private/account`).get();
  const storedEmail = (
    (privateAccount.get("authEmail") as string | undefined) ??
    (privateAccount.get("email") as string | undefined) ??
    ""
  )
    .trim()
    .toLowerCase();
  if (storedEmail.length > 0 && storedEmail === configuredAdmin) {
    return;
  }

  throw new HttpsError(
    "permission-denied",
    `Admin access required. Sign in with ${adminEmail.value()}.`,
  );
}

function targetTypeToCollection(targetType: string): string {
  switch (targetType) {
    case "country":
      return "countries";
    case "fixture":
      return "fixtures";
    case "standing":
      return "standings";
    case "user":
      return "users";
    default:
      throw new HttpsError("invalid-argument", `Unsupported targetType: ${targetType}`);
  }
}
