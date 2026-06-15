const nameAliases: Record<string, string[]> = {
  cote_divoire: ["ivory coast", "cote d'ivoire", "côte d'ivoire"],
  south_korea: ["korea republic", "south korea", "republic of korea", "korea"],
  turkey: ["turkiye", "turkey"],
  czech_republic: ["czechia", "czech republic"],
  congo_dr: ["dr congo", "congo dr", "congo-democratic", "democratic republic of the congo"],
  usa: ["usa", "united states"],
  bosnia_herzegovina: ["bosnia", "bosnia and herzegovina", "bosnia-herzegovina"],
  cabo_verde: ["cabo verde", "cape verde"],
  iran: ["iran", "ir iran"],
  curacao: ["curacao", "curaçao"],
  england: ["england"],
  scotland: ["scotland"],
  south_africa: ["south africa"],
};

export function normalizeTeamName(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

export function countryMatchesApiTeam(
  country: {id: string; name?: string; abbreviation?: string},
  apiTeam: {name?: string; code?: string; tla?: string},
): boolean {
  const apiName = normalizeTeamName(apiTeam.name ?? "");
  const localName = normalizeTeamName(country.name ?? "");
  const localAbbrev = (country.abbreviation ?? "").toLowerCase();
  const apiCode = (apiTeam.code ?? apiTeam.tla ?? "").toLowerCase();

  if (apiName.length > 0 && apiName === localName) {
    return true;
  }
  if (apiCode.length > 0 && apiCode === localAbbrev) {
    return true;
  }
  if (apiName.length > 0 && localName.length > 0) {
    if (apiName.includes(localName) || localName.includes(apiName)) {
      return true;
    }
  }
  for (const alias of nameAliases[country.id] ?? []) {
    if (normalizeTeamName(alias) === apiName) {
      return true;
    }
  }
  return false;
}

export type CountryMaps = {
  countryIdByApiTeamId: Map<number, string>;
  apiTeamIdByCountryId: Map<string, number>;
};

export function buildCountryMapsFromFirestore(
  docs: Array<{
    id: string;
    get: (field: string) => unknown;
  }>,
): CountryMaps {
  const countryIdByApiTeamId = new Map<number, string>();
  const apiTeamIdByCountryId = new Map<string, number>();
  for (const doc of docs) {
    const apiId = doc.get("footballDataTeamId") as number | undefined;
    if (apiId != null && apiId > 0) {
      countryIdByApiTeamId.set(apiId, doc.id);
      apiTeamIdByCountryId.set(doc.id, apiId);
    }
  }
  return {countryIdByApiTeamId, apiTeamIdByCountryId};
}

export function enrichCountryMapsFromApiTeams(
  maps: CountryMaps,
  countries: Array<{id: string; name?: string; abbreviation?: string}>,
  apiTeams: Array<{
    id?: number;
    name?: string;
    tla?: string;
    team?: {id?: number; name?: string; code?: string; tla?: string};
  }>,
): number {
  let enriched = 0;
  for (const item of apiTeams) {
    const team = item.team ?? item;
    const apiId = team.id;
    if (apiId == null || apiId <= 0) {
      continue;
    }
    if (maps.countryIdByApiTeamId.has(apiId)) {
      continue;
    }
    const local = countries.find((country) => countryMatchesApiTeam(country, team));
    if (!local) {
      continue;
    }
    if (maps.apiTeamIdByCountryId.has(local.id)) {
      continue;
    }
    maps.countryIdByApiTeamId.set(apiId, local.id);
    maps.apiTeamIdByCountryId.set(local.id, apiId);
    enriched += 1;
  }
  return enriched;
}
