import process from "node:process";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {
  buildFixtureUpdates,
  findLocalFixture,
  buildLocalFixtureIndex,
} from "../lib/sync-helpers.js";
import {
  fetchWorldCupMatches,
  fetchWorldCupTeams,
  toRemoteFixture,
} from "../lib/football-data-client.js";
import {
  buildCountryMapsFromFirestore,
  enrichCountryMapsFromApiTeams,
} from "../lib/country-api-mapper.js";

const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
const token = process.env.FOOTBALL_DATA_TOKEN;

if (!projectId) {
  console.error("Set GCLOUD_PROJECT=testing-fe25d");
  process.exit(1);
}
if (!token) {
  console.error("Set FOOTBALL_DATA_TOKEN from football-data.org.");
  process.exit(1);
}

if (!process.env.GOOGLE_CLOUD_QUOTA_PROJECT && projectId) {
  process.env.GOOGLE_CLOUD_QUOTA_PROJECT = projectId;
}

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const db = getFirestore();

const countriesSnap = await db.collection("countries").get();
const countries = countriesSnap.docs.map((doc) => ({
  id: doc.id,
  name: doc.get("name"),
  abbreviation: doc.get("abbreviation"),
}));
const countryMaps = buildCountryMapsFromFirestore(countriesSnap.docs);
const apiTeams = await fetchWorldCupTeams(token);
const enriched = enrichCountryMapsFromApiTeams(countryMaps, countries, apiTeams);

const fixturesSnap = await db.collection("fixtures").get();
const localFixtures = fixturesSnap.docs
  .filter((doc) => doc.id.startsWith("m"))
  .map((doc) => ({id: doc.id, ...doc.data()}));

const apiMatches = await fetchWorldCupMatches(token);
const remoteFixtures = apiMatches.map(toRemoteFixture);

const buildResult = buildFixtureUpdates(
  remoteFixtures,
  localFixtures,
  countryMaps.countryIdByApiTeamId,
  countryMaps.apiTeamIdByCountryId,
);

console.log("=== Sync diagnosis (football-data.org) ===");
console.log(`Countries in Firestore: ${countriesSnap.size}`);
console.log(`Countries with team IDs: ${countryMaps.apiTeamIdByCountryId.size}`);
console.log(`Countries enriched from API: ${enriched}`);
console.log(`Local fixtures (m*): ${localFixtures.length}`);
console.log(`API matches returned: ${remoteFixtures.length}`);
console.log(`Updates ready: ${buildResult.updates.length}`);
console.log(`Skipped admin: ${buildResult.skippedAdmin}`);
console.log(`Skipped unmatched: ${buildResult.skippedUnmatched}`);
console.log(`Skipped unchanged: ${buildResult.skippedUnchanged}`);

if (remoteFixtures.length > 0) {
  const index = buildLocalFixtureIndex(
    localFixtures,
    countryMaps.apiTeamIdByCountryId,
  );
  console.log("\nFirst 5 API matches:");
  for (const item of remoteFixtures.slice(0, 5)) {
    const local = findLocalFixture(item, index);
    console.log({
      apiId: item.id,
      date: item.kickoff,
      status: item.status,
      home: item.homeTeamId,
      away: item.awayTeamId,
      goals: [item.homeScore, item.awayScore],
      matchedLocalId: local?.id ?? null,
    });
  }
}

if (localFixtures.length > 0) {
  console.log("\nFirst local fixture:");
  console.log(localFixtures[0]);
}

const syncState = await db.doc("syncState/current").get();
console.log("\nLast syncState:", syncState.data());
