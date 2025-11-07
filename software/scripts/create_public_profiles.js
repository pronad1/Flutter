// IMMEDIATE FIX - Run this to create publicProfiles for existing users
// This will populate the publicProfiles collection from existing users data

const admin = require('firebase-admin');

// Initialize Firebase Admin
// Make sure you have GOOGLE_APPLICATION_CREDENTIALS environment variable set
// or provide the path to your service account JSON file
admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

async function createPublicProfiles() {
    console.log('🚀 Starting migration: Creating publicProfiles from users...\n');

    try {
        // Get all users
        const usersSnapshot = await db.collection('users').get();

        if (usersSnapshot.empty) {
            console.log('❌ No users found in the database!');
            return;
        }

        console.log(`📊 Found ${usersSnapshot.size} users to process\n`);

        let successCount = 0;
        let skipCount = 0;
        let errorCount = 0;

        // Process each user
        for (const userDoc of usersSnapshot.docs) {
            const userId = userDoc.id;
            const userData = userDoc.data();

            try {
                // Check if publicProfile already exists
                const publicProfileRef = db.collection('publicProfiles').doc(userId);
                const publicProfileSnap = await publicProfileRef.get();

                if (publicProfileSnap.exists) {
                    console.log(`⏭️  Skipping ${userId} - publicProfile already exists`);
                    skipCount++;
                    continue;
                }

                // Create publicProfile from users data
                const publicProfileData = {
                    name: userData.name || userData.displayName || '',
                    bio: userData.bio || '',
                    photoUrl: userData.profilePicUrl || userData.photoUrl || '',
                    email: userData.email || '',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                };

                await publicProfileRef.set(publicProfileData);

                console.log(`✅ Created publicProfile for: ${userId} (${publicProfileData.name || 'No name'})`);
                successCount++;

            } catch (error) {
                console.error(`❌ Error processing ${userId}:`, error.message);
                errorCount++;
            }
        }

        console.log('\n📈 Migration Summary:');
        console.log(`   ✅ Successfully created: ${successCount}`);
        console.log(`   ⏭️  Skipped (already exists): ${skipCount}`);
        console.log(`   ❌ Errors: ${errorCount}`);
        console.log(`   📊 Total processed: ${usersSnapshot.size}`);

        if (successCount > 0) {
            console.log('\n🎉 Migration completed successfully!');
            console.log('👉 Now run your Flutter app and tap a product - it should work!');
        }

    } catch (error) {
        console.error('💥 Fatal error during migration:', error);
        process.exit(1);
    }
}

// Run the migration
createPublicProfiles()
    .then(() => {
        console.log('\n✨ Migration script finished');
        process.exit(0);
    })
    .catch((error) => {
        console.error('💥 Migration failed:', error);
        process.exit(1);
    });
