import {groupIds} from "./bracket-rules";
import {FixtureRecord, GroupStanding, StandingRow} from "./standings-calculator";

export type GroupPick = {
  groupId: string;
  firstCountryId: string;
  secondCountryId: string;
  thirdCountryId: string;
};

export type OfficialGroupPlacements = {
  groupPicks: GroupPick[];
  bestThirdGroupIds: string[];
};

const AUTOMATED_GROUP_PLACEMENT_UPDATED_BY = new Set([
  "score-bracket-trigger",
  "football-data-sync",
  "standings-auto",
  "leaderboard-recalc",
]);

export function isGroupStageComplete(fixtures: FixtureRecord[]): boolean {
  const groupFixtures = fixtures.filter(
    (fixture) => fixture.stage === "group" && fixture.id.startsWith("m"),
  );
  return (
    groupFixtures.length > 0 &&
    groupFixtures.every((fixture) => fixture.status === "finished")
  );
}

export function isGroupStandingComplete(standing: GroupStanding): boolean {
  return (
    standing.rows.length >= 3 &&
    standing.rows.every((row) => row.played === 3)
  );
}

export function areStandingsComplete(standings: GroupStanding[]): boolean {
  return groupIds.every((groupId) => {
    const standing = standings.find((item) => item.groupId === groupId);
    return standing != null && isGroupStandingComplete(standing);
  });
}

export function officialPlacementsFromStandings(
  standings: GroupStanding[],
  options: {requireAllGroups?: boolean} = {},
): OfficialGroupPlacements | null {
  const requireAllGroups = options.requireAllGroups ?? true;
  const completeStandings: GroupStanding[] = [];

  for (const groupId of groupIds) {
    const standing = standings.find((item) => item.groupId === groupId);
    if (standing == null || !isGroupStandingComplete(standing)) {
      if (requireAllGroups) {
        return null;
      }
      continue;
    }
    completeStandings.push(standing);
  }

  if (completeStandings.length === 0) {
    return null;
  }

  const groupPicks: GroupPick[] = completeStandings.map((standing) => {
    const rows = standing.rows;
    return {
      groupId: standing.groupId,
      firstCountryId: rows[0].countryId,
      secondCountryId: rows[1].countryId,
      thirdCountryId: rows[2].countryId,
    };
  });

  return {
    groupPicks,
    bestThirdGroupIds: bestThirdGroupIds(completeStandings),
  };
}

export function officialPlacementsForScoring(
  standings: GroupStanding[],
  storedPlacements: OfficialGroupPlacements | null | undefined,
): OfficialGroupPlacements | null {
  return (
    officialPlacementsFromStandings(standings, {requireAllGroups: false}) ??
    storedPlacements ??
    null
  );
}

function bestThirdGroupIds(completeStandings: GroupStanding[]): string[] {
  if (completeStandings.length < 8) {
    return [];
  }

  const thirdRows = completeStandings
    .filter((standing) => standing.rows.length >= 3)
    .map((standing) => ({groupId: standing.groupId, row: standing.rows[2]}));
  if (thirdRows.length < 8) {
    return [];
  }

  return thirdRows
    .sort((a, b) => compareStandingRows(a.row, b.row))
    .slice(0, 8)
    .map((row) => row.groupId)
    .sort();
}

export function advancingCountryIds(
  placements: OfficialGroupPlacements,
): string[] {
  const bestThirdGroups = new Set(placements.bestThirdGroupIds);
  const advancers = new Set<string>();
  for (const pick of placements.groupPicks) {
    advancers.add(pick.firstCountryId);
    advancers.add(pick.secondCountryId);
    if (bestThirdGroups.has(pick.groupId)) {
      advancers.add(pick.thirdCountryId);
    }
  }
  return [...advancers].sort();
}

export function shouldAutoUpdateGroupPlacements(
  existingUpdatedBy: string | undefined,
): boolean {
  if (existingUpdatedBy == null || existingUpdatedBy.length === 0) {
    return true;
  }
  return AUTOMATED_GROUP_PLACEMENT_UPDATED_BY.has(existingUpdatedBy);
}

function compareStandingRows(
  a: StandingRow,
  b: StandingRow,
): number {
  if (b.points !== a.points) return b.points - a.points;
  if (b.goalDifference !== a.goalDifference) {
    return b.goalDifference - a.goalDifference;
  }
  if (b.goalsFor !== a.goalsFor) return b.goalsFor - a.goalsFor;
  return a.countryId.localeCompare(b.countryId);
}
