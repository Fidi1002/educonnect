/* eslint-disable no-console */
const admin = require("firebase-admin");

const isApplyMode = process.argv.includes("--apply");
const projectId = process.env.FIREBASE_PROJECT_ID || "aplikasi-educonnect-id";

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error(
      "GOOGLE_APPLICATION_CREDENTIALS belum di-set. Set path service-account JSON terlebih dulu.",
    );
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId,
  });

  const db = admin.firestore();
  const tutorsSnapshot = await db.collection("tutors").get();

  let scanned = 0;
  let updated = 0;
  let deactivated = 0;
  let backfilledPublicFields = 0;
  let noChange = 0;

  const batch = db.batch();

  for (const tutorDoc of tutorsSnapshot.docs) {
    scanned += 1;
    const data = tutorDoc.data() || {};
    const geo = data.geo || {};
    const geopoint = geo.geopoint;
    const geohash = geo.geohash;

    const hasValidGeo =
      geopoint &&
      typeof geohash === "string" &&
      geohash.length > 0 &&
      !(geopoint.latitude === 0 && geopoint.longitude === 0);

    const updates = {};

    if (!hasValidGeo) {
      updates.isActive = false;
      updates.migrationNote = "deactivated_missing_or_invalid_geo";
      updates.migratedAt = admin.firestore.FieldValue.serverTimestamp();
      deactivated += 1;
    }

    if (!data.displayName || typeof data.displayName !== "string") {
      const userDoc = await db.collection("users").doc(tutorDoc.id).get();
      const userMap = userDoc.data() || {};
      updates.displayName = userMap.displayName || "Tutor";
      backfilledPublicFields += 1;
    }

    if (!data.photoUrl || typeof data.photoUrl !== "string") {
      const userDoc = await db.collection("users").doc(tutorDoc.id).get();
      const userMap = userDoc.data() || {};
      updates.photoUrl = userMap.photoUrl || "";
      backfilledPublicFields += 1;
    }

    if (Object.keys(updates).length === 0) {
      noChange += 1;
      continue;
    }

    updated += 1;
    if (isApplyMode) {
      batch.set(tutorDoc.ref, updates, { merge: true });
    }
  }

  if (isApplyMode && updated > 0) {
    await batch.commit();
  }

  console.log("==== Tutor Geo Migration Summary ====");
  console.log(`projectId: ${projectId}`);
  console.log(`mode: ${isApplyMode ? "APPLY" : "DRY_RUN"}`);
  console.log(`scanned: ${scanned}`);
  console.log(`updated: ${updated}`);
  console.log(`deactivated_invalid_geo: ${deactivated}`);
  console.log(`backfilled_public_fields: ${backfilledPublicFields}`);
  console.log(`no_change: ${noChange}`);
}

main().catch((error) => {
  console.error("Migration failed:", error);
  process.exit(1);
});
