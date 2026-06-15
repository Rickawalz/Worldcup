import process from "node:process";
import {initializeApp, applicationDefault} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";

const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID;
const emailArg = process.argv.find((arg) => arg.startsWith("--email="));
const email = (emailArg?.split("=")[1] ?? "rgw1985@hotmail.com").trim().toLowerCase();

if (!projectId && !process.env.FIRESTORE_EMULATOR_HOST) {
  console.error(
    "Set GCLOUD_PROJECT/FIREBASE_PROJECT_ID before running this script.",
  );
  process.exit(1);
}

initializeApp({
  credential: applicationDefault(),
  projectId,
});

if (!process.env.GOOGLE_CLOUD_QUOTA_PROJECT && projectId) {
  process.env.GOOGLE_CLOUD_QUOTA_PROJECT = projectId;
}

const auth = getAuth();
const user = await auth.getUserByEmail(email);
const existingClaims = user.customClaims ?? {};

await auth.setCustomUserClaims(user.uid, {
  ...existingClaims,
  admin: true,
});

console.log(`Granted admin claim to ${email} (${user.uid}).`);
console.log("Sign out and sign back in on the app so the new token is picked up.");
