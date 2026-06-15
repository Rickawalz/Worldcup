import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {calculateStandings} from "../lib/standings-calculator.js";

describe("standings calculator", () => {
  it("calculates group A standings from finished fixtures", () => {
    const standings = calculateStandings([
      {
        id: "m1",
        stage: "group",
        status: "finished",
        roundLabel: "GROUP A",
        homeCountryId: "mexico",
        awayCountryId: "south_africa",
        homeScore: 2,
        awayScore: 1,
      },
      {
        id: "m2",
        stage: "group",
        status: "finished",
        roundLabel: "GROUP A",
        homeCountryId: "south_korea",
        awayCountryId: "czech_republic",
        homeScore: 1,
        awayScore: 1,
      },
    ]);

    const groupA = standings.find((standing) => standing.groupId === "A");
    assert.ok(groupA);
    assert.equal(groupA.rows[0].countryId, "mexico");
    assert.equal(groupA.rows[0].points, 3);
    assert.equal(groupA.rows[0].goalDifference, 1);
    assert.equal(groupA.rows[0].form, "W");
    assert.equal(
      groupA.rows.find((row) => row.countryId === "south_korea")?.form,
      "D",
    );
  });
});
