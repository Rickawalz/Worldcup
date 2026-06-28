import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  knockoutPointsForStage,
  scoreBracket,
  scoreGroupPlacements,
} from "../lib/scoring.js";

describe("scoring", () => {
  it("scores exact and partial group placements", () => {
    const breakdown = scoreBracket(
      {
        status: "submitted",
        groupPicks: [
          {
            groupId: "A",
            firstCountryId: "mexico",
            secondCountryId: "south_korea",
            thirdCountryId: "czech_republic",
          },
        ],
        knockoutPicks: [
          {
            slotId: "m73",
            stage: "roundOf32",
            winnerCountryId: "mexico",
          },
        ],
      },
      {
        groupPlacements: {
          groupPicks: [
            {
              groupId: "A",
              firstCountryId: "mexico",
              secondCountryId: "south_africa",
              thirdCountryId: "south_korea",
            },
          ],
          bestThirdGroupIds: ["A"],
        },
        knockoutWinnersBySlot: {m73: "mexico"},
      },
    );

    assert.equal(breakdown.groupScore, 4);
    assert.equal(breakdown.knockoutScore, 1);
    assert.equal(breakdown.totalScore, 5);
  });

  it("returns zero group score when official placements are missing", () => {
    assert.equal(
      scoreGroupPlacements(
        [
          {
            groupId: "A",
            firstCountryId: "mexico",
            secondCountryId: "south_korea",
            thirdCountryId: "czech_republic",
          },
        ],
        null,
      ),
      0,
    );
  });

  it("uses doubling knockout ladder for correct winners", () => {
    const breakdown = scoreBracket(
      {
        status: "submitted",
        knockoutPicks: [
          {slotId: "m73", stage: "roundOf32", winnerCountryId: "mexico"},
          {slotId: "m89", stage: "roundOf16", winnerCountryId: "brazil"},
          {slotId: "m104", stage: "finalMatch", winnerCountryId: "argentina"},
        ],
      },
      {
        knockoutWinnersBySlot: {
          m73: "mexico",
          m89: "brazil",
          m104: "argentina",
        },
      },
    );

    assert.equal(breakdown.knockoutScore, 19);
    assert.equal(knockoutPointsForStage("roundOf32"), 1);
    assert.equal(knockoutPointsForStage("finalMatch"), 16);
  });
});
