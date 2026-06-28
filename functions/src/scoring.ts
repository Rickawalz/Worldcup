import {GroupPick, OfficialGroupPlacements} from "./group-placements";

export type KnockoutPick = {
  slotId: string;
  stage: string;
  winnerCountryId: string;
};

export type FinalScoreTiebreaker = {
  championScore?: number;
  runnerUpScore?: number;
};

export type BracketRecord = {
  status?: string;
  groupPicks?: GroupPick[];
  knockoutPicks?: KnockoutPick[];
  finalScoreTiebreaker?: FinalScoreTiebreaker;
};

export type OfficialResultsRecord = {
  groupPlacements?: OfficialGroupPlacements | null;
  knockoutWinnersBySlot?: Record<string, string>;
  finalChampionScore?: number | null;
  finalRunnerUpScore?: number | null;
};

export type ScoreBreakdown = {
  groupScore: number;
  knockoutScore: number;
  totalScore: number;
  tiebreakerDistance: number;
};

const GROUP_TOP_THREE_POINTS = 1;
const GROUP_EXACT_PLACEMENT_BONUS = 2;

const KNOCKOUT_POINTS_BY_STAGE: Record<string, number> = {
  roundOf32: 1,
  roundOf16: 2,
  quarterfinal: 4,
  semifinal: 8,
  finalMatch: 16,
};

export function knockoutPointsForStage(stage: string): number {
  return KNOCKOUT_POINTS_BY_STAGE[stage] ?? 0;
}

export function scoreBracket(
  bracket: BracketRecord,
  officialResults: OfficialResultsRecord,
): ScoreBreakdown {
  const groupScore = scoreGroupPlacements(
    bracket.groupPicks ?? [],
    officialResults.groupPlacements,
  );
  const knockoutScore = (bracket.knockoutPicks ?? []).reduce((score, pick) => {
    const actualWinner = officialResults.knockoutWinnersBySlot?.[pick.slotId];
    if (actualWinner == null || actualWinner !== pick.winnerCountryId) {
      return score;
    }
    return score + knockoutPointsForStage(pick.stage);
  }, 0);
  const tiebreakerDistance = tiebreakerDistanceFor(
    bracket.finalScoreTiebreaker,
    officialResults.finalChampionScore,
    officialResults.finalRunnerUpScore,
  );

  return {
    groupScore,
    knockoutScore,
    totalScore: groupScore + knockoutScore,
    tiebreakerDistance,
  };
}

export function scoreGroupPlacements(
  predictedPicks: GroupPick[],
  actualPlacements: OfficialGroupPlacements | null | undefined,
): number {
  if (actualPlacements?.groupPicks?.length == null) {
    return 0;
  }

  const actualByGroup = new Map(
    actualPlacements.groupPicks.map((pick) => [pick.groupId, pick]),
  );

  let score = 0;
  for (const predicted of predictedPicks) {
    const actual = actualByGroup.get(predicted.groupId);
    if (actual == null) {
      continue;
    }
    score += scorePredictedSlot(predicted.firstCountryId, 1, actual);
    score += scorePredictedSlot(predicted.secondCountryId, 2, actual);
    score += scorePredictedSlot(predicted.thirdCountryId ?? "", 3, actual);
  }
  return score;
}

function scorePredictedSlot(
  predictedCountryId: string,
  predictedRank: number,
  actual: GroupPick,
): number {
  if (predictedCountryId.length === 0) {
    return 0;
  }
  if (!topThreeCountryIds(actual).has(predictedCountryId)) {
    return 0;
  }
  if (predictedCountryId === countryIdAtRank(actual, predictedRank)) {
    return GROUP_TOP_THREE_POINTS + GROUP_EXACT_PLACEMENT_BONUS;
  }
  return GROUP_TOP_THREE_POINTS;
}

function topThreeCountryIds(pick: GroupPick): Set<string> {
  return new Set(
    [pick.firstCountryId, pick.secondCountryId, pick.thirdCountryId].filter(
      (countryId): countryId is string =>
        countryId != null && countryId.length > 0,
    ),
  );
}

function countryIdAtRank(pick: GroupPick, rank: number): string {
  switch (rank) {
    case 1:
      return pick.firstCountryId;
    case 2:
      return pick.secondCountryId;
    case 3:
      return pick.thirdCountryId ?? "";
    default:
      return "";
  }
}

function tiebreakerDistanceFor(
  tiebreaker: FinalScoreTiebreaker | undefined,
  championScore: number | null | undefined,
  runnerUpScore: number | null | undefined,
): number {
  if (championScore == null || runnerUpScore == null) {
    return 0;
  }
  return (
    Math.abs((tiebreaker?.championScore ?? 0) - championScore) +
    Math.abs((tiebreaker?.runnerUpScore ?? 0) - runnerUpScore)
  );
}
