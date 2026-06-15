import {RemoteFixture} from "./sync-helpers";

const BASE_URL = "https://api.football-data.org/v4";

export type FootballDataTeam = {
  id: number;
  name: string;
  shortName?: string;
  tla?: string;
};

export type FootballDataMatch = {
  id: number;
  utcDate: string;
  status: string;
  homeTeam: {id: number; name?: string; tla?: string};
  awayTeam: {id: number; name?: string; tla?: string};
  score?: {
    fullTime?: {home?: number | null; away?: number | null};
    regularTime?: {home?: number | null; away?: number | null};
  };
};

export async function fetchWorldCupTeams(
  token: string,
): Promise<FootballDataTeam[]> {
  const response = await fetch(`${BASE_URL}/competitions/WC/teams`, {
    headers: {"X-Auth-Token": token},
  });
  if (!response.ok) {
    throw new Error(`football-data.org teams failed: ${response.status}`);
  }
  const payload = (await response.json()) as {
    teams?: FootballDataTeam[];
    message?: string;
  };
  if (payload.message) {
    throw new Error(`football-data.org teams error: ${payload.message}`);
  }
  return payload.teams ?? [];
}

export async function fetchWorldCupMatches(
  token: string,
): Promise<FootballDataMatch[]> {
  const response = await fetch(`${BASE_URL}/competitions/WC/matches`, {
    headers: {"X-Auth-Token": token},
  });
  if (!response.ok) {
    throw new Error(`football-data.org matches failed: ${response.status}`);
  }
  const payload = (await response.json()) as {
    matches?: FootballDataMatch[];
    message?: string;
  };
  if (payload.message) {
    throw new Error(`football-data.org matches error: ${payload.message}`);
  }
  return payload.matches ?? [];
}

export function toRemoteFixture(match: FootballDataMatch): RemoteFixture {
  const homeScore = scoreFromMatch(match, "home");
  const awayScore = scoreFromMatch(match, "away");
  const finished = match.status === "FINISHED" || match.status === "AWARDED";
  let homeWinner: boolean | undefined;
  let awayWinner: boolean | undefined;
  if (finished && homeScore != null && awayScore != null && homeScore !== awayScore) {
    homeWinner = homeScore > awayScore;
    awayWinner = awayScore > homeScore;
  }

  return {
    id: match.id,
    kickoff: match.utcDate,
    status: match.status,
    homeTeamId: match.homeTeam.id,
    awayTeamId: match.awayTeam.id,
    homeWinner,
    awayWinner,
    homeScore,
    awayScore,
  };
}

function scoreFromMatch(
  match: FootballDataMatch,
  side: "home" | "away",
): number | null {
  const liveScore = match.score?.regularTime?.[side];
  const fullTimeScore = match.score?.fullTime?.[side];
  const value = fullTimeScore ?? liveScore;
  return value ?? null;
}
