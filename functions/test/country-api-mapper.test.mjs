import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  countryMatchesApiTeam,
  enrichCountryMapsFromApiTeams,
  buildCountryMapsFromFirestore,
} from "../lib/country-api-mapper.js";

describe("country api mapper", () => {
  it("matches aliases like Korea Republic and Ivory Coast", () => {
    assert.equal(
      countryMatchesApiTeam(
        {id: "south_korea", name: "Korea Republic", abbreviation: "KOR"},
        {name: "South Korea", tla: "KOR"},
      ),
      true,
    );
    assert.equal(
      countryMatchesApiTeam(
        {id: "cote_divoire", name: "Côte d'Ivoire", abbreviation: "CIV"},
        {name: "Ivory Coast", tla: "CIV"},
      ),
      true,
    );
  });

  it("enriches missing team ids from football-data team list", () => {
    const maps = buildCountryMapsFromFirestore([
      {id: "mexico", get: () => 0},
      {id: "south_africa", get: () => 0},
    ]);
    const enriched = enrichCountryMapsFromApiTeams(
      maps,
      [
        {id: "mexico", name: "Mexico", abbreviation: "MEX"},
        {id: "south_africa", name: "South Africa", abbreviation: "RSA"},
      ],
      [
        {id: 770, name: "Mexico", tla: "MEX"},
        {id: 771, name: "South Africa", tla: "RSA"},
      ],
    );
    assert.equal(enriched, 2);
    assert.equal(maps.apiTeamIdByCountryId.get("mexico"), 770);
    assert.equal(maps.apiTeamIdByCountryId.get("south_africa"), 771);
  });
});
