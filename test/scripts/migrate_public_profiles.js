// scripts/migrate_public_profiles.js
// Usage: set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON, then run:
// node scripts/migrate_public_profiles.js

const admin = require('firebase-admin');
const path = require('path');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('Please set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON file.');
    process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();

async function migrate() {
    console.log('Starting migration: users -> publicProfiles');
    const usersSnap = await db.collection('users').get();
    console.log(`Found ${usersSnap.size} users.`);
    let count = 0;
    for (const doc of usersSnap.docs) {
        const uid = doc.id;
        const d = doc.data();
        const pub = {
            name: (d.name || d.displayName || '') + '',
            bio: (d.bio || '') + '',
            photoUrl: (d.profilePicUrl || d.photoUrl || '') + '',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await db.collection('publicProfiles').doc(uid).set(pub, { merge: true });
        count++;
        if (count % 50 === 0) console.log(`Processed ${count}/${usersSnap.size}`);
    }
    console.log(`Migration complete. ${count} profiles updated.`);
}

migrate().catch(err => { console.error('Migration failed', err); process.exit(2); });
