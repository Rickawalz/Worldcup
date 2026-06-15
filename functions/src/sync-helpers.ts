export type RemoteFixture = {
  id?: number;
  kickoff?: string;
  status?: string;
  homeTeamId?: number;
  awayTeamId?: number;
  homeWinner?: boolean;
  awayWinner?: boolean;
  homeScore?: number | null;
  awayScore?: number | null;
};

export type LocalFixtureDoc = {
  id: string;
  externalId?: string;
  stage?: string;
  kickoff?: string;
  status?: string;
  homeCountryId?: string | null;
  awayCountryId?: string | null;
  homeScore?: number | null;
  awayScore?: number | null;
  winnerCountryId?: string | null;
  updatedBy?: string | null;
};

export type FixtureUpdate = {
  docId: string;
  status: string;
  homeScore: number | null;
  awayScore: number | null;
  winnerCountryId: string | null;
  stage?: string;
  previousStatus?: string;
};

export type SyncBuildResult = {
  updates: FixtureUpdate[];
  skippedAdmin: number;
  skippedUnmatched: number;
  skippedUnchanged: number;
};

/** Poll shortly before kickoff through full time + ET/PEN buffer. */
export const MATCH_SYNC_PRE_KICKOFF_MS = 10 * 60 * 1000;
export const MATCH_SYNC_POST_KICKOFF_MS = 150 * 60 * 1000;

export function isFixtureInActiveSyncWindow(
  fixture: LocalFixtureDoc,
  nowMs: number,
): boolean {
  if (!fixture.kickoff) {
    return false;
  }
  if (fixture.updatedBy) {
    return false;
  }
  if (fixture.status === "finished" || fixture.status === "postponed") {
    return false;
  }

  const kickoffMs = Date.parse(fixture.kickoff);
  if (Number.isNaN(kickoffMs)) {
    return false;
  }

  const windowStart = kickoffMs - MATCH_SYNC_PRE_KICKOFF_MS;
  const windowEnd = kickoffMs + MATCH_SYNC_POST_KICKOFF_MS;
  return nowMs >= windowStart && nowMs <= windowEnd;
}

export function shouldRunMatchWindowSync(
  fixtures: LocalFixtureDoc[],
  nowMs: number,
): boolean {
  return fixtures.some((fixture) =>
    isFixtureInActiveSyncWindow(fixture, nowMs),
  );
}

export function buildFixtureMatchKey(
  homeTeamId: number,
  awayTeamId: number,
  kickoffIso: string,
): string {
  const date = kickoffDateFromIso(kickoffIso);
  return `${homeTeamId}:${awayTeamId}:${date}`;
}

export function kickoffDateFromIso(kickoffIso: string): string {
  const parsed = Date.parse(kickoffIso);
  if (Number.isNaN(parsed)) {
    return kickoffIso.slice(0, 10);
  }
  return new Date(parsed).toISOString().slice(0, 10);
}

export function kickoffDatesAround(kickoffIso: string): string[] {
  const parsed = Date.parse(kickoffIso);
  if (Number.isNaN(parsed)) {
    return [kickoffIso.slice(0, 10)];
  }
  const dates = new Set<string>();
  for (const offsetHours of [-12, 0, 12]) {
    const shifted = new Date(parsed + offsetHours * 60 * 60 * 1000);
    dates.add(shifted.toISOString().slice(0, 10));
  }
  return [...dates];
}

export function buildLocalFixtureIndex(
  fixtures: LocalFixtureDoc[],
  teamIdByCountryId: Map<string, number>,
): Map<string, LocalFixtureDoc> {
  const index = new Map<string, LocalFixtureDoc>();
  for (const fixture of fixtures) {
    if (fixture.externalId) {
      index.set(`external:${fixture.externalId}`, fixture);
    }
    const homeTeamId = fixture.homeCountryId
      ? teamIdByCountryId.get(fixture.homeCountryId)
      : undefined;
    const awayTeamId = fixture.awayCountryId
      ? teamIdByCountryId.get(fixture.awayCountryId)
      : undefined;
    if (
      homeTeamId != null &&
      awayTeamId != null &&
      fixture.kickoff &&
      homeTeamId > 0 &&
      awayTeamId > 0
    ) {
      for (const date of kickoffDatesAround(fixture.kickoff)) {
        index.set(`${homeTeamId}:${awayTeamId}:${date}`, fixture);
        index.set(`${awayTeamId}:${homeTeamId}:${date}`, fixture);
      }
    }
  }
  return index;
}

export function findLocalFixture(
  remote: RemoteFixture,
  index: Map<string, LocalFixtureDoc>,
): LocalFixtureDoc | undefined {
  const remoteId = remote.id;
  if (remoteId != null) {
    const byExternal = index.get(`external:${remoteId}`);
    if (byExternal) {
      return byExternal;
    }
  }

  const homeTeamId = remote.homeTeamId;
  const awayTeamId = remote.awayTeamId;
  const kickoff = remote.kickoff;
  if (homeTeamId != null && awayTeamId != null && kickoff) {
    for (const date of kickoffDatesAround(kickoff)) {
      const direct = index.get(`${homeTeamId}:${awayTeamId}:${date}`);
      if (direct) {
        return direct;
      }
      const swapped = index.get(`${awayTeamId}:${homeTeamId}:${date}`);
      if (swapped) {
        return swapped;
      }
    }
  }
  return undefined;
}

export function statusFromRemote(status: string): string {
  const normalized = status.toUpperCase();
  if (["IN_PLAY", "PAUSED", "LIVE"].includes(normalized)) {
    return "live";
  }
  if (["FINISHED", "AWARDED"].includes(normalized)) {
    return "finished";
  }
  if (["POSTPONED", "CANCELLED", "SUSPENDED"].includes(normalized)) {
    return "postponed";
  }
  return "scheduled";
}

/** @deprecated Use statusFromRemote for football-data.org statuses. */
export function statusFromApi(status: string): string {
  if (["1H", "HT", "2H", "ET", "P", "BT"].includes(status)) return "live";
  if (["FT", "AET", "PEN"].includes(status)) return "finished";
  if (["PST", "CANC", "ABD"].includes(status)) return "postponed";
  return "scheduled";
}

export function winnerCountryIdFromRemote(
  remote: RemoteFixture,
  countryIdByTeamId: Map<number, string>,
): string | null {
  const homeTeamId = remote.homeTeamId;
  const awayTeamId = remote.awayTeamId;
  if (remote.homeWinner === true && homeTeamId != null) {
    return countryIdByTeamId.get(homeTeamId) ?? null;
  }
  if (remote.awayWinner === true && awayTeamId != null) {
    return countryIdByTeamId.get(awayTeamId) ?? null;
  }
  const homeScore = remote.homeScore;
  const awayScore = remote.awayScore;
  if (
    homeScore != null &&
    awayScore != null &&
    homeScore !== awayScore &&
    homeTeamId != null &&
    awayTeamId != null
  ) {
    const winnerTeamId = homeScore > awayScore ? homeTeamId : awayTeamId;
    return countryIdByTeamId.get(winnerTeamId) ?? null;
  }
  return null;
}

/** @deprecated Use winnerCountryIdFromRemote. */
export function winnerCountryIdFromApi(
  apiItem: {
    teams?: {
      home?: {id?: number; winner?: boolean};
      away?: {id?: number; winner?: boolean};
    };
  },
  countryIdByApiTeamId: Map<number, string>,
): string | null {
  const homeTeamId = apiItem.teams?.home?.id;
  const awayTeamId = apiItem.teams?.away?.id;
  if (apiItem.teams?.home?.winner === true && homeTeamId != null) {
    return countryIdByApiTeamId.get(homeTeamId) ?? null;
  }
  if (apiItem.teams?.away?.winner === true && awayTeamId != null) {
    return countryIdByApiTeamId.get(awayTeamId) ?? null;
  }
  return null;
}

export function buildFixtureUpdates(
  remoteFixtures: RemoteFixture[],
  localFixtures: LocalFixtureDoc[],
  countryIdByTeamId: Map<number, string>,
  teamIdByCountryId: Map<string, number>,
): SyncBuildResult {
  const index = buildLocalFixtureIndex(localFixtures, teamIdByCountryId);
  const updates: FixtureUpdate[] = [];
  let skippedAdmin = 0;
  let skippedUnmatched = 0;
  let skippedUnchanged = 0;

  for (const remote of remoteFixtures) {
    const local = findLocalFixture(remote, index);
    if (!local) {
      skippedUnmatched += 1;
      continue;
    }
    if (local.updatedBy) {
      skippedAdmin += 1;
      continue;
    }

    const status = statusFromRemote(remote.status ?? "SCHEDULED");
    const homeScore = remote.homeScore ?? null;
    const awayScore = remote.awayScore ?? null;
    const winnerCountryId = winnerCountryIdFromRemote(remote, countryIdByTeamId);

    if (
      local.status === status &&
      local.homeScore === homeScore &&
      local.awayScore === awayScore &&
      (local.winnerCountryId ?? null) === winnerCountryId
    ) {
      skippedUnchanged += 1;
      continue;
    }

    updates.push({
      docId: local.id,
      status,
      homeScore,
      awayScore,
      winnerCountryId,
      stage: local.stage,
      previousStatus: local.status,
    });
  }

  return {
    updates,
    skippedAdmin,
    skippedUnmatched,
    skippedUnchanged,
  };
}

export function winnerScore(
  homeScore: number | null,
  awayScore: number | null,
  winnerCountryId: string | null,
  homeCountryId?: string | null,
  awayCountryId?: string | null,
): number | null {
  if (
    homeScore == null ||
    awayScore == null ||
    winnerCountryId == null ||
    !homeCountryId ||
    !awayCountryId
  ) {
    return null;
  }
  if (winnerCountryId === homeCountryId) return homeScore;
  if (winnerCountryId === awayCountryId) return awayScore;
  return null;
}

export function runnerUpScore(
  homeScore: number | null,
  awayScore: number | null,
  winnerCountryId: string | null,
  homeCountryId?: string | null,
  awayCountryId?: string | null,
): number | null {
  if (
    homeScore == null ||
    awayScore == null ||
    winnerCountryId == null ||
    !homeCountryId ||
    !awayCountryId
  ) {
    return null;
  }
  if (winnerCountryId === homeCountryId) return awayScore;
  if (winnerCountryId === awayCountryId) return homeScore;
  return null;
}
