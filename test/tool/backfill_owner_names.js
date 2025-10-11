// tool/backfill_owner_names.js
// Backfill script to populate `ownerName` on items by reading users/{ownerId}
// Usage:
// 1) Install dependencies: npm install firebase-admin
// 2) Ensure you have a service account JSON and set env var GOOGLE_APPLICATION_CREDENTIALS to its path
//    or pass --serviceAccount /path/to/sa.json
// 3) Run: node tool/backfill_owner_names.js --project your-project-id

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function argvOption(name) {
    const idx = process.argv.indexOf(name);
    if (idx === -1) return null;
    return process.argv[idx + 1];
}

async function main() {
    const serviceAccount = argvOption('--serviceAccount') || process.env.GOOGLE_APPLICATION_CREDENTIALS;
    const projectId = argvOption('--project') || process.env.GCLOUD_PROJECT;

    if (!serviceAccount && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        console.error('ERROR: set GOOGLE_APPLICATION_CREDENTIALS or pass --serviceAccount');
        process.exit(1);
    }

    if (!projectId) {
        console.error('ERROR: pass --project <projectId> or set GCLOUD_PROJECT env var');
        process.exit(1);
    }

    // Initialize admin
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId,
        });
    }

    const db = admin.firestore();

    console.log('Starting backfill: scanning items for missing ownerName...');

    const batchSize = 200; // Firestore batch limit
    let processed = 0;
    let updated = 0;

    const itemsRef = db.collection('items');
    const snapshot = await itemsRef.get();
    console.log(`Found ${snapshot.size} items.`);

    // Map ownerId -> ownerName for caching
    const ownerCache = {};

    const batches = [];
    let batch = db.batch();
    let bcount = 0;

    for (const doc of snapshot.docs) {
        processed++;
        const data = doc.data();
        const ownerId = (data.ownerId || '').toString();
        const ownerName = (data.ownerName || '').toString();

        if (!ownerId) continue;
        if (ownerName && ownerName.trim() !== '') continue; // already set

        // get ownerName from cache or users collection
        if (!ownerCache[ownerId]) {
            try {
                const u = await db.collection('users').doc(ownerId).get();
                const ud = u.data();
                let name = '';
                if (ud) name = (ud.name || ud.displayName || '').toString();
                if (!name) name = '(No name)';
                ownerCache[ownerId] = name;
            } catch (e) {
                console.warn(`Failed to read user ${ownerId}: ${e}`);
                ownerCache[ownerId] = '(No name)';
            }
        }

        const newName = ownerCache[ownerId];
        batch.update(doc.ref, { ownerName: newName });
        bcount++;
        updated++;

        if (bcount >= batchSize) {
            batches.push(batch.commit());
            batch = db.batch();
            bcount = 0;
        }
    }

    if (bcount > 0) batches.push(batch.commit());

    console.log(`Committing ${batches.length} batches...`);
    await Promise.all(batches);

    console.log(`Completed. Processed ${processed} items, updated ${updated} items.`);
    process.exit(0);
}

main().catch((e) => {
    console.error('Fatal error:', e);
    process.exit(1);
});
