import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  buildFixtureMatchKey,
  buildFixtureUpdates,
  findLocalFixture,
  buildLocalFixtureIndex,
  isFixtureInActiveSyncWindow,
  shouldRunMatchWindowSync,
  statusFromRemote,
  winnerCountryIdFromRemote,
} from "../lib/sync-helpers.js";
import {toRemoteFixture} from "../lib/football-data-client.js";

describe("match window sync gate", () => {
  const kickoff = "2026-06-11T19:00:00.000Z";
  const fixture = {
    id: "m1",
    kickoff,
    status: "scheduled",
    homeCountryId: "mexico",
    awayCountryId: "south_africa",
  };

  it("polls shortly before kickoff through the post-match buffer", () => {
    const kickoffMs = Date.parse(kickoff);
    assert.equal(
      isFixtureInActiveSyncWindow(fixture, kickoffMs - 5 * 60 * 1000),
      true,
    );
    assert.equal(
      isFixtureInActiveSyncWindow(fixture, kickoffMs + 90 * 60 * 1000),
      true,
    );
    assert.equal(
      isFixtureInActiveSyncWindow(fixture, kickoffMs + 140 * 60 * 1000),
      true,
    );
  });

  it("skips idle periods outside the match window", () => {
    const kickoffMs = Date.parse(kickoff);
    assert.equal(
      isFixtureInActiveSyncWindow(fixture, kickoffMs - 30 * 60 * 1000),
      false,
    );
    assert.equal(
      isFixtureInActiveSyncWindow(fixture, kickoffMs + 180 * 60 * 1000),
      false,
    );
  });

  it("skips finished, postponed, and admin-overridden fixtures", () => {
    const kickoffMs = Date.parse(kickoff);
    const duringMatch = kickoffMs + 60 * 60 * 1000;
    assert.equal(
      isFixtureInActiveSyncWindow({...fixture, status: "finished"}, duringMatch),
      false,
    );
    assert.equal(
      isFixtureInActiveSyncWindow({...fixture, status: "postponed"}, duringMatch),
      false,
    );
    assert.equal(
      isFixtureInActiveSyncWindow(
        {...fixture, updatedBy: "admin"},
        duringMatch,
      ),
      false,
    );
  });

  it("runs when any fixture is in an active window", () => {
    const kickoffMs = Date.parse(kickoff);
    assert.equal(
      shouldRunMatchWindowSync(
        [fixture],
        kickoffMs + 30 * 60 * 1000,
      ),
      true,
    );
    assert.equal(
      shouldRunMatchWindowSync(
        [fixture],
        kickoffMs - 60 * 60 * 1000,
      ),
      false,
    );
  });
});

describe("fixture matching", () => {
  const teamIdByCountryId = new Map([
    ["mexico", 770],
    ["south_africa", 771],
  ]);
  const countryIdByTeamId = new Map([
    [770, "mexico"],
    [771, "south_africa"],
  ]);

  const localFixtures = [
    {
      id: "m1",
      externalId: "1",
      stage: "group",
      kickoff: "2026-06-11T19:00:00.000Z",
      homeCountryId: "mexico",
      awayCountryId: "south_africa",
      status: "scheduled",
      homeScore: null,
      awayScore: null,
    },
  ];

  it("matches by home/away team IDs and kickoff date", () => {
    const index = buildLocalFixtureIndex(localFixtures, teamIdByCountryId);
    const remote = {
      id: 999,
      kickoff: "2026-06-11T19:00:00.000Z",
      status: "FINISHED",
      homeTeamId: 770,
      awayTeamId: 771,
      homeWinner: true,
      awayWinner: false,
      homeScore: 2,
      awayScore: 1,
    };
    assert.equal(findLocalFixture(remote, index)?.id, "m1");
  });

  it("falls back to externalId when it matches the remote fixture id", () => {
    const index = buildLocalFixtureIndex(
      [{...localFixtures[0], externalId: "999"}],
      teamIdByCountryId,
    );
    const remote = {
      id: 999,
      kickoff: "2026-06-11T19:00:00.000Z",
      homeTeamId: 770,
      awayTeamId: 771,
    };
    assert.equal(findLocalFixture(remote, index)?.id, "m1");
  });

  it("builds stable match keys from kickoff date", () => {
    assert.equal(
      buildFixtureMatchKey(770, 771, "2026-06-11T19:00:00.000Z"),
      "770:771:2026-06-11",
    );
  });
});

describe("sync update building", () => {
  it("skips fixtures with updatedBy set", () => {
    const result = buildFixtureUpdates(
      [
        {
          id: 1,
          kickoff: "2026-06-11T19:00:00.000Z",
          status: "FINISHED",
          homeTeamId: 770,
          awayTeamId: 771,
          homeWinner: true,
          awayWinner: false,
          homeScore: 2,
          awayScore: 1,
        },
      ],
      [
        {
          id: "m1",
          externalId: "1",
          kickoff: "2026-06-11T19:00:00.000Z",
          homeCountryId: "mexico",
          awayCountryId: "south_africa",
          updatedBy: "admin-user",
        },
      ],
      new Map([
        [770, "mexico"],
        [771, "south_africa"],
      ]),
      new Map([
        ["mexico", 770],
        ["south_africa", 771],
      ]),
    );
    assert.equal(result.updates.length, 0);
    assert.equal(result.skippedAdmin, 1);
  });

  it("maps remote winner team IDs to winnerCountryId", () => {
    const result = buildFixtureUpdates(
      [
        {
          id: 1,
          kickoff: "2026-06-11T19:00:00.000Z",
          status: "FINISHED",
          homeTeamId: 770,
          awayTeamId: 771,
          homeWinner: true,
          awayWinner: false,
          homeScore: 2,
          awayScore: 1,
        },
      ],
      [
        {
          id: "m1",
          externalId: "1",
          kickoff: "2026-06-11T19:00:00.000Z",
          homeCountryId: "mexico",
          awayCountryId: "south_africa",
          status: "scheduled",
          homeScore: null,
          awayScore: null,
        },
      ],
      new Map([
        [770, "mexico"],
        [771, "south_africa"],
      ]),
      new Map([
        ["mexico", 770],
        ["south_africa", 771],
      ]),
    );
    assert.equal(result.updates.length, 1);
    assert.equal(result.updates[0].winnerCountryId, "mexico");
    assert.equal(result.updates[0].status, "finished");
    assert.equal(result.updates[0].homeScore, 2);
    assert.equal(result.updates[0].awayScore, 1);
  });

  it("maps live and postponed statuses", () => {
    assert.equal(statusFromRemote("IN_PLAY"), "live");
    assert.equal(statusFromRemote("POSTPONED"), "postponed");
    assert.equal(statusFromRemote("SCHEDULED"), "scheduled");
  });

  it("resolves winnerCountryId from remote scores", () => {
    const winner = winnerCountryIdFromRemote(
      {
        homeTeamId: 770,
        awayTeamId: 771,
        homeScore: 0,
        awayScore: 2,
      },
      new Map([
        [770, "mexico"],
        [771, "south_africa"],
      ]),
    );
    assert.equal(winner, "south_africa");
  });

  it("maps football-data match payloads into remote fixtures", () => {
    const remote = toRemoteFixture({
      id: 42,
      utcDate: "2026-06-11T19:00:00.000Z",
      status: "FINISHED",
      homeTeam: {id: 770, tla: "MEX"},
      awayTeam: {id: 771, tla: "RSA"},
      score: {fullTime: {home: 1, away: 0}},
    });
    assert.equal(remote.homeScore, 1);
    assert.equal(remote.awayScore, 0);
    assert.equal(remote.homeWinner, true);
  });
});
