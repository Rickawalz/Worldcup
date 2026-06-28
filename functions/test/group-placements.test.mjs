import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  advancingCountryIds,
  officialPlacementsFromStandings,
  shouldAutoUpdateGroupPlacements,
} from "../lib/group-placements.js";
import {groupIds} from "../lib/bracket-rules.js";
import {calculateStandings} from "../lib/standings-calculator.js";

function finishedGroupFixture(
  id,
  groupId,
  homeCountryId,
  awayCountryId,
  homeScore,
  awayScore,
) {
  return {
    id,
    stage: "group",
    status: "finished",
    roundLabel: `GROUP ${groupId}`,
    homeCountryId,
    awayCountryId,
    homeScore,
    awayScore,
  };
}

describe("group placements", () => {
  it("derives official placements and best third-place teams from complete standings", () => {
    const standings = groupIds.map((groupId, index) => ({
      groupId,
      rows: [
        {
          countryId: `first_${groupId}`,
          rank: 1,
          played: 3,
          won: 2,
          drawn: 1,
          lost: 0,
          goalsFor: 5,
          goalsAgainst: 2,
          goalDifference: 3,
          points: 7,
          form: "W,W,D",
        },
        {
          countryId: `second_${groupId}`,
          rank: 2,
          played: 3,
          won: 1,
          drawn: 2,
          lost: 0,
          goalsFor: 4,
          goalsAgainst: 3,
          goalDifference: 1,
          points: 5,
          form: "D,W,D",
        },
        {
          countryId: `third_${groupId}`,
          rank: 3,
          played: 3,
          won: index,
          drawn: 0,
          lost: 3 - index,
          goalsFor: index + 1,
          goalsAgainst: 4,
          goalDifference: index - 3,
          points: index * 3,
          form: "L,L,W",
        },
        {
          countryId: `fourth_${groupId}`,
          rank: 4,
          played: 3,
          won: 0,
          drawn: 0,
          lost: 3,
          goalsFor: 1,
          goalsAgainst: 6,
          goalDifference: -5,
          points: 0,
          form: "L,L,L",
        },
      ],
      overrideOrderCountryIds: [],
    }));

    const placements = officialPlacementsFromStandings(standings);
    assert.ok(placements);
    assert.equal(placements.groupPicks.length, 12);
    assert.equal(advancingCountryIds(placements).length, 32);
    assert.equal(placements.bestThirdGroupIds.length, 8);
  });

  it("returns null when group standings are incomplete", () => {
    const fixtures = [
      finishedGroupFixture("m1", "A", "mexico", "south_africa", 2, 1),
    ];
    const standings = calculateStandings(fixtures);
    assert.equal(officialPlacementsFromStandings(standings), null);
  });

  it("allows auto update for automated sources but not admin overrides", () => {
    assert.equal(shouldAutoUpdateGroupPlacements(undefined), true);
    assert.equal(shouldAutoUpdateGroupPlacements("score-bracket-trigger"), true);
    assert.equal(shouldAutoUpdateGroupPlacements("admin-user-id"), false);
  });
});
