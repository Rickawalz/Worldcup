import {groupCountryIds, groupIds} from "./bracket-rules";

export type FixtureRecord = {
  id: string;
  stage?: string;
  status?: string;
  roundLabel?: string;
  kickoff?: string;
  homeCountryId?: string | null;
  awayCountryId?: string | null;
  homeScore?: number | null;
  awayScore?: number | null;
};

export type StandingRow = {
  countryId: string;
  rank: number;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
  points: number;
  form: string;
};

export type GroupStanding = {
  groupId: string;
  rows: StandingRow[];
  overrideOrderCountryIds: string[];
  updatedAt?: string;
  updatedBy?: string;
};

type MutableStanding = {
  countryId: string;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  goalsFor: number;
  goalsAgainst: number;
  recentResults: string[];
};

const MAX_FORM_LENGTH = 5;

export function calculateStandings(
  fixtures: FixtureRecord[],
  existingStandings: Array<{
    groupId: string;
    overrideOrderCountryIds?: string[];
  }> = [],
  updatedAt?: string,
  updatedBy?: string,
): GroupStanding[] {
  const overrides = new Map(
    existingStandings.map((standing) => [
      standing.groupId,
      standing.overrideOrderCountryIds ?? [],
    ]),
  );

  return groupIds.map((groupId) =>
    calculateGroupStanding(
      groupId,
      fixtures,
      overrides.get(groupId) ?? [],
      updatedAt,
      updatedBy,
    ),
  );
}

function calculateGroupStanding(
  groupId: string,
  fixtures: FixtureRecord[],
  overrideOrderCountryIds: string[],
  updatedAt?: string,
  updatedBy?: string,
): GroupStanding {
  const countryIds = groupCountryIds[groupId] ?? [];
  const stats = new Map<string, MutableStanding>(
    countryIds.map((countryId) => [
      countryId,
      {
        countryId,
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        goalsFor: 0,
        goalsAgainst: 0,
        recentResults: [],
      },
    ]),
  );

  const groupFixtures = fixtures
    .filter(
      (fixture) =>
        fixture.stage === "group" &&
        fixture.status === "finished" &&
        fixture.roundLabel?.trim().toUpperCase() === `GROUP ${groupId}` &&
        fixture.homeCountryId &&
        fixture.awayCountryId &&
        fixture.homeScore != null &&
        fixture.awayScore != null,
    )
    .sort((a, b) => {
      const aTime = a.kickoff ? Date.parse(a.kickoff) : 0;
      const bTime = b.kickoff ? Date.parse(b.kickoff) : 0;
      return aTime - bTime;
    });

  for (const fixture of groupFixtures) {
    const home = stats.get(fixture.homeCountryId!);
    const away = stats.get(fixture.awayCountryId!);
    if (!home || !away) {
      continue;
    }

    applyResult(home, fixture.homeScore!, fixture.awayScore!);
    applyResult(away, fixture.awayScore!, fixture.homeScore!);
  }

  const rows = [...stats.values()]
    .map((standing) => toRow(standing))
    .sort(defaultCompare);
  const orderedRows = applyOverride(rows, overrideOrderCountryIds);

  return {
    groupId,
    rows: orderedRows.map((row, index) => ({...row, rank: index + 1})),
    overrideOrderCountryIds,
    updatedAt,
    updatedBy,
  };
}

function applyResult(
  standing: MutableStanding,
  goalsFor: number,
  goalsAgainst: number,
): void {
  standing.played += 1;
  standing.goalsFor += goalsFor;
  standing.goalsAgainst += goalsAgainst;
  if (goalsFor > goalsAgainst) {
    standing.won += 1;
    standing.recentResults.push("W");
  } else if (goalsFor < goalsAgainst) {
    standing.lost += 1;
    standing.recentResults.push("L");
  } else {
    standing.drawn += 1;
    standing.recentResults.push("D");
  }
  while (standing.recentResults.length > MAX_FORM_LENGTH) {
    standing.recentResults.shift();
  }
}

function toRow(standing: MutableStanding): StandingRow {
  return {
    countryId: standing.countryId,
    rank: 0,
    played: standing.played,
    won: standing.won,
    drawn: standing.drawn,
    lost: standing.lost,
    goalsFor: standing.goalsFor,
    goalsAgainst: standing.goalsAgainst,
    goalDifference: standing.goalsFor - standing.goalsAgainst,
    points: standing.won * 3 + standing.drawn,
    form: standing.recentResults.join(","),
  };
}

function defaultCompare(a: StandingRow, b: StandingRow): number {
  if (b.points !== a.points) return b.points - a.points;
  if (b.goalDifference !== a.goalDifference) {
    return b.goalDifference - a.goalDifference;
  }
  if (b.goalsFor !== a.goalsFor) return b.goalsFor - a.goalsFor;
  return a.countryId.localeCompare(b.countryId);
}

function applyOverride(
  rows: StandingRow[],
  overrideOrderCountryIds: string[],
): StandingRow[] {
  if (overrideOrderCountryIds.length === 0) {
    return rows;
  }
  const byCountryId = new Map(rows.map((row) => [row.countryId, row]));
  const ordered: StandingRow[] = [];
  for (const countryId of overrideOrderCountryIds) {
    const row = byCountryId.get(countryId);
    if (row) {
      ordered.push(row);
      byCountryId.delete(countryId);
    }
  }
  ordered.push(...byCountryId.values());
  return ordered;
}
