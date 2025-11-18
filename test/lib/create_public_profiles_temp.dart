import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quick script to create publicProfiles for existing users
/// Run this once, then delete this file
void main() async {
  final db = FirebaseFirestore.instance;
  
  // Get all users
  final usersSnapshot = await db.collection('users').get();
  
  print('📊 Found ${usersSnapshot.docs.length} users');
  
  int created = 0;
  int skipped = 0;
  
  for (final userDoc in usersSnapshot.docs) {
    final userId = userDoc.id;
    final userData = userDoc.data();
    
    // Check if publicProfile exists
    final publicProfileDoc = await db.collection('publicProfiles').doc(userId).get();
    
    if (publicProfileDoc.exists) {
      print('⏭️  Skipping $userId - already has publicProfile');
      skipped++;
      continue;
    }
    
    // Create publicProfile
    await db.collection('publicProfiles').doc(userId).set({
      'name': userData['name'] ?? userData['displayName'] ?? '',
      'bio': userData['bio'] ?? '',
      'photoUrl': userData['profilePicUrl'] ?? userData['photoUrl'] ?? '',
      'email': userData['email'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Created publicProfile for $userId (${userData['name'] ?? 'No name'})');
    created++;
  }
  
  print('\n📈 Summary:');
  print('   Created: $created');
  print('   Skipped: $skipped');
  print('   Total: ${usersSnapshot.docs.length}');
  print('\n🎉 Done! Now run flutter run and tap products');
}
