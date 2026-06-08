import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {defineSecret} from "firebase-functions/params";

initializeApp();

const db = getFirestore();
const apiFootballKey = defineSecret("API_FOOTBALL_KEY");

type ApiFootballFixture = {
  fixture?: {
    id?: number;
    date?: string;
    status?: {short?: string};
  };
  league?: {round?: string};
  teams?: {
    home?: {id?: number; winner?: boolean};
    away?: {id?: number; winner?: boolean};
  };
  goals?: {home?: number; away?: number};
};

type ApiFootballStanding = {
  rank?: number;
  group?: string;
  team?: {id?: number; name?: string; logo?: string};
  points?: number;
  goalsDiff?: number;
  all?: {
    played?: number;
    win?: number;
    draw?: number;
    lose?: number;
    goals?: {for?: number; against?: number};
  };
};

export const syncWorldCupData = onSchedule(
  {
    schedule: "every 30 minutes",
    secrets: [apiFootballKey],
    timeoutSeconds: 120,
  },
  async () => {
    const key = apiFootballKey.value();
    if (!key) {
      throw new Error("API_FOOTBALL_KEY is not configured.");
    }

    const [fixtures, standings] = await Promise.all([
      fetchApiFootball<{response: ApiFootballFixture[]}>(
        "fixtures?league=1&season=2026",
        key,
      ),
      fetchApiFootball<{response: Array<{league?: {standings?: ApiFootballStanding[][]}}>}>(
        "standings?league=1&season=2026",
        key,
      ),
    ]);

    const batch = db.batch();
    for (const item of fixtures.response ?? []) {
      const externalId = String(item.fixture?.id ?? "");
      if (!externalId) {
        continue;
      }
      const homeApiId = item.teams?.home?.id;
      const awayApiId = item.teams?.away?.id;
      const winnerApiId = item.teams?.home?.winner
        ? homeApiId
        : item.teams?.away?.winner
          ? awayApiId
          : null;

      batch.set(
        db.collection("fixtures").doc(externalId),
        {
          externalId,
          roundLabel: item.league?.round ?? "",
          stage: stageFromRound(item.league?.round ?? ""),
          kickoff: item.fixture?.date ?? null,
          status: statusFromApi(item.fixture?.status?.short ?? "NS"),
          homeApiFootballTeamId: homeApiId ?? null,
          awayApiFootballTeamId: awayApiId ?? null,
          homeScore: item.goals?.home ?? null,
          awayScore: item.goals?.away ?? null,
          winnerApiFootballTeamId: winnerApiId,
          syncedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    const groups = standings.response?.[0]?.league?.standings ?? [];
    for (const groupRows of groups) {
      const groupId = (groupRows[0]?.group ?? "unknown")
        .replace(/^Group\s+/i, "")
        .trim();
      batch.set(
        db.collection("standings").doc(groupId),
        {
          groupId,
          rows: groupRows.map((row) => ({
            rank: row.rank ?? null,
            apiFootballTeamId: row.team?.id ?? null,
            teamName: row.team?.name ?? "",
            flagUrl: row.team?.logo ?? "",
            points: row.points ?? 0,
            goalDifference: row.goalsDiff ?? 0,
            played: row.all?.played ?? 0,
            won: row.all?.win ?? 0,
            drawn: row.all?.draw ?? 0,
            lost: row.all?.lose ?? 0,
            goalsFor: row.all?.goals?.for ?? 0,
            goalsAgainst: row.all?.goals?.against ?? 0,
          })),
          syncedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    }

    await batch.commit();
  },
);

export const submitAdminOverride = onCall(async (request) => {
  assertAdmin(request.auth?.token);
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
  assertAdmin(request.auth?.token);
  await rebuildLeaderboard();
});

export const scoreBracketOnResult = onDocumentWritten(
  "fixtures/{fixtureId}",
  async (event) => {
    const after = event.data?.after.data();
    if (!after || after.status !== "finished") {
      return;
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

async function fetchApiFootball<T>(path: string, key: string): Promise<T> {
  const response = await fetch(`https://v3.football.api-sports.io/${path}`, {
    headers: {"x-apisports-key": key},
  });
  if (!response.ok) {
    throw new Error(`API-Football ${path} failed: ${response.status}`);
  }
  return (await response.json()) as T;
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

function assertAdmin(token: Record<string, unknown> | undefined): void {
  if (token?.admin !== true) {
    throw new HttpsError("permission-denied", "Admin custom claim required.");
  }
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

function stageFromRound(round: string): string {
  const normalized = round.toLowerCase();
  if (normalized.includes("round of 32")) return "roundOf32";
  if (normalized.includes("round of 16")) return "roundOf16";
  if (normalized.includes("quarter")) return "quarterfinal";
  if (normalized.includes("semi")) return "semifinal";
  if (normalized.includes("final")) return "finalMatch";
  return "group";
}

function statusFromApi(status: string): string {
  if (["1H", "HT", "2H", "ET", "P", "BT"].includes(status)) return "live";
  if (["FT", "AET", "PEN"].includes(status)) return "finished";
  if (["PST", "CANC", "ABD"].includes(status)) return "postponed";
  return "scheduled";
}
