// lib/src/ui/screens/profile/public_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/review_service.dart';
import '../../../services/item_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _reviewService = ReviewService();

  int _selectedRating = 5;
  final _textCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-sync profile data when viewing own profile
    _autoSyncProfile();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // Auto-sync profile data from users to publicProfiles if viewing own profile
  Future<void> _autoSyncProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != widget.userId) {
      debugPrint('⏭️ Auto-sync skipped: Not viewing own profile');
      return; // Not viewing own profile
    }
    
    debugPrint('🔄 Starting auto-sync for ${widget.userId}');
    
    try {
      // Read from users collection
      final userDoc = await _db.collection('users').doc(widget.userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ users/${widget.userId} does not exist');
        return;
      }
      
      final userData = userDoc.data() ?? {};
      debugPrint('📖 Read from users collection:');
      debugPrint('   name: "${userData['name']}"');
      debugPrint('   bio: "${userData['bio']}"');
      debugPrint('   photoUrl: "${userData['photoUrl']}"');
      debugPrint('   profilePicUrl: "${userData['profilePicUrl']}"');
      debugPrint('   email: "${userData['email']}"');
      
      // Check publicProfiles
      final publicDoc = await _db.collection('publicProfiles').doc(widget.userId).get();
      
      if (!publicDoc.exists) {
        // Create publicProfiles with all data
        debugPrint('🆕 Creating publicProfiles/${widget.userId}...');
        await _db.collection('publicProfiles').doc(widget.userId).set({
          'name': userData['name'] ?? userData['displayName'] ?? '',
          'bio': userData['bio'] ?? '',
          'photoUrl': userData['photoUrl'] ?? userData['profilePicUrl'] ?? '',
          'profilePicUrl': userData['photoUrl'] ?? userData['profilePicUrl'] ?? '',
          'email': userData['email'] ?? currentUser.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Auto-created publicProfiles/${widget.userId}');
      } else {
        // ALWAYS sync - force update to ensure data is current
        debugPrint('🔧 Updating publicProfiles/${widget.userId}...');
        await _db.collection('publicProfiles').doc(widget.userId).set({
          'name': userData['name'] ?? userData['displayName'] ?? '',
          'bio': userData['bio'] ?? '',
          'photoUrl': userData['photoUrl'] ?? userData['profilePicUrl'] ?? '',
          'profilePicUrl': userData['photoUrl'] ?? userData['profilePicUrl'] ?? '',
          'email': userData['email'] ?? currentUser.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ Force-synced all data to publicProfiles/${widget.userId}');
      }
    } catch (e) {
      debugPrint('❌ Auto-sync failed: $e');
    }
  }

  Future<void> _sendEmail(String to) async {
    if (to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address available')),
      );
      return;
    }
    
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      query: 'subject=Hello from Donation App', // Optional: Add default subject
    );
    
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client. Please check if you have an email app installed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening email: $e')),
      );
    }
  }

  void _showRulesDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Profile Not Complete'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This user\'s public profile is missing some information.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              const Text('Why?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('The profile data (bio, photo) hasn\'t been synced to the public profile yet.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Quick Fix:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('If you are this user:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(height: 6),
                    Text('1. Go to Profile tab', style: TextStyle(fontSize: 12)),
                    Text('2. Click Edit Profile button', style: TextStyle(fontSize: 12)),
                    Text('3. Make any small change (add a space to bio)', style: TextStyle(fontSize: 12)),
                    Text('4. Click Save Changes', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 6),
                    Text('✅ Your bio and photo will be visible to everyone!', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Note: This only needs to be done once to sync your profile.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }


  Future<void> _submitReview(String donorId) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log in to leave reviews')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await _reviewService.submitReview(donorId: donorId, rating: _selectedRating, text: _textCtrl.text);
      _textCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _starSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final idx = i + 1;
        return IconButton(
          icon: Icon(
            idx <= _selectedRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => setState(() => _selectedRating = idx),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _db.collection('publicProfiles').doc(widget.userId).get(),
        builder: (context, publicSnap) {
          if (publicSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // Debug logging
          if (publicSnap.hasError) {
            debugPrint('❌ Error reading publicProfiles/${widget.userId}: ${publicSnap.error}');
          } else if (publicSnap.hasData && publicSnap.data!.exists) {
            debugPrint('✅ Successfully read publicProfiles/${widget.userId}');
          } else {
            debugPrint('⚠️ publicProfiles/${widget.userId} does not exist');
          }

          // If a public profile exists, check if we need to enrich it with private data
          if (publicSnap.hasData && publicSnap.data!.exists) {
            final publicData = publicSnap.data!.data() ?? {};
            
            // Check if bio/photo/email are empty - if so, try to fetch from users collection
            final bio = (publicData['bio'] ?? '').toString();
            final photo = (publicData['photoUrl'] ?? publicData['profilePicUrl'] ?? '').toString();
            final email = (publicData['email'] ?? '').toString();
            
            if (bio.isEmpty || photo.isEmpty || email.isEmpty) {
              // Try to read from users collection to enrich the profile
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _db.collection('users').doc(widget.userId).get(),
                builder: (ctx, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    // Show what we have while loading
                    return _profileContent(publicData);
                  }
                  
                  // If we can read users collection, merge the data
                  if (userSnap.hasData && userSnap.data!.exists && !userSnap.hasError) {
                    final userData = userSnap.data!.data() ?? {};
                    final mergedData = {
                      ...publicData,
                      if (bio.isEmpty && userData['bio'] != null) 'bio': userData['bio'],
                      if (photo.isEmpty && userData['photoUrl'] != null) 'photoUrl': userData['photoUrl'],
                      if (photo.isEmpty && userData['profilePicUrl'] != null) 'profilePicUrl': userData['profilePicUrl'],
                      if (email.isEmpty && userData['email'] != null) 'email': userData['email'],
                    };
                    debugPrint('✅ Enriched publicProfiles with users data for ${widget.userId}');
                    return _profileContent(mergedData);
                  }
                  
                  // Can't read users collection or it doesn't exist, show public data
                  return _profileContent(publicData);
                },
              );
            }
            
            // Public data is complete, use it
            return _profileContent(publicData);
          }

          // Otherwise try reading the private users/{uid} doc (may be allowed for signed-in users or admins)
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _db.collection('users').doc(widget.userId).get(),
            builder: (ctx, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (userSnap.hasError) {
                final err = userSnap.error;
                String s = err.toString();
                if (s.contains('permission-denied') || s.contains('PERMISSION_DENIED')) {
                  // permission denied on users/{uid} → try to auto-create publicProfiles from items
                  return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: _db
                        .collection('items')
                        .where('ownerId', isEqualTo: widget.userId)
                        .limit(1)
                        .get(),
                    builder: (ctx3, itemsCheckSnap) {
                      if (itemsCheckSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      
                      // If we found items, try to create publicProfiles from ownerName
                      if (itemsCheckSnap.hasData && itemsCheckSnap.data!.docs.isNotEmpty) {
                        final firstItem = itemsCheckSnap.data!.docs.first.data();
                        final ownerName = firstItem['ownerName'] ?? 'Anonymous';
                        
                        // Try to auto-create publicProfiles (best effort)
                        _db.collection('publicProfiles').doc(widget.userId).set({
                          'name': ownerName,
                          'bio': '',
                          'photoUrl': '',
                          'email': '',
                          'createdAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true)).then((_) {
                          debugPrint('✅ Auto-created publicProfiles/${widget.userId}');
                          // Trigger rebuild to show the profile
                          if (mounted) setState(() {});
                        }).catchError((e) {
                          debugPrint('⚠️ Could not auto-create publicProfiles/${widget.userId}: $e');
                        });
                        
                        // Show loading while creating
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Creating profile...'),
                            ],
                          ),
                        );
                      }
                      
                      // No items found, show fallback UI with dialog
                      return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: _db
                        .collection('items')
                        .where('ownerId', isEqualTo: widget.userId)
                        .orderBy('createdAt', descending: true)
                        .limit(20)
                        .get(),
                    builder: (ctx2, itemsSnap) {
                      if (itemsSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final items = itemsSnap.data?.docs ?? [];
                      final inferredName = items.isNotEmpty ? (items.first.data()['ownerName'] ?? '') : '';
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(inferredName.toString().isEmpty ? 'Donor profile (limited)' : inferredName.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text('Detailed profile is restricted by Firestore rules. Showing donated items as a fallback.', textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              if (items.isEmpty)
                                const Text('No publicly readable items found for this donor.'),
                              if (items.isNotEmpty)
                                SizedBox(
                                  height: 180,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (c, i) {
                                      final it = items[i].data();
                                      final title = (it['title'] ?? '').toString();
                                      final imageUrl = (it['imageUrl'] ?? '').toString();
                                      return SizedBox(
                                        width: 160,
                                        child: Card(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: imageUrl.isNotEmpty
                                                    ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover)
                                                    : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported_outlined))),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(title.isEmpty ? '(Untitled)' : title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                                ElevatedButton(onPressed: () => _showRulesDialog(context), child: const Text('Why & How to Fix')),
                                ElevatedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
                              ])
                            ],
                          ),
                        ),
                      );
                    },
                  );
                    },
                  ); // Close itemsCheckSnap FutureBuilder
                }

                // Other error: show message
                return Center(child: Text('Failed to load profile: ${userSnap.error}'));
              }

              if (!userSnap.hasData || !userSnap.data!.exists) {
                // No user doc and no public profile → show dialog
                WidgetsBinding.instance.addPostFrameCallback((_) => _showRulesDialog(context));
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Profile Not Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text('This user\'s profile could not be loaded.', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              // userSnap has data → use it to show profile
              final userData = userSnap.data!.data() ?? {};
              return _profileContent(userData);
            },
          );
        },
      ),
    );
  }

  Widget _profileContent(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? '').toString();
    final bio = (data['bio'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final avatar = (data['photoUrl'] ?? data['profilePicUrl'] ?? '').toString();

    // Debug: Print what data we have
    debugPrint('📊 Profile data for ${widget.userId}:');
    debugPrint('   name: ${name.isEmpty ? "(empty)" : name}');
    debugPrint('   bio: ${bio.isEmpty ? "(empty)" : bio}');
    debugPrint('   email: ${email.isEmpty ? "(empty)" : email}');
    debugPrint('   avatar: ${avatar.isEmpty ? "(empty)" : avatar}');

    final isProfileIncomplete = bio.isEmpty || avatar.isEmpty;
    final isOwnProfile = _auth.currentUser?.uid == widget.userId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show banner if profile is incomplete
          if (isProfileIncomplete) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isOwnProfile 
                            ? 'Your public profile is incomplete. Please update your profile.'
                            : 'This profile is incomplete.',
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (isOwnProfile) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Force sync now
                        await _autoSyncProfile();
                        // Refresh the page
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Profile synced! Pull down to refresh.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Sync Profile Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Profile header with avatar and info
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) as ImageProvider : null,
                backgroundColor: Colors.blue.shade100,
                child: avatar.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.blue) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '(No name)' : name, 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // Rating display at top with stars
                    FutureBuilder<Map<String, dynamic>>(
                      future: _reviewService.fetchRatingSummary(widget.userId),
                      builder: (ctx, ratSnap) {
                        if (!ratSnap.hasData) return const SizedBox.shrink();
                        final avgRating = (ratSnap.data?['avg'] ?? 0.0) as double;  // Fixed: was 'average', should be 'avg'
                        final count = (ratSnap.data?['count'] ?? 0) as int;
                        return Row(
                          children: [
                            ...List.generate(5, (i) {
                              if (i < avgRating.floor()) {
                                return const Icon(Icons.star, size: 18, color: Colors.amber);
                              } else if (i < avgRating.ceil() && avgRating % 1 != 0) {
                                return const Icon(Icons.star_half, size: 18, color: Colors.amber);
                              } else {
                                return const Icon(Icons.star_border, size: 18, color: Colors.amber);
                              }
                            }),
                            const SizedBox(width: 6),
                            Text(
                              '${avgRating.toStringAsFixed(1)} ($count)',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bio.isEmpty ? 'No bio provided' : bio,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Email button if email exists
          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Send Email'),
                onPressed: () => _sendEmail(email),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          // Rating summary and reviews
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _reviewService.streamReviewsForDonor(widget.userId),
            builder: (context, rsnap) {
              if (rsnap.hasError) return const SizedBox.shrink();
              final docs = rsnap.data?.docs ?? [];
              double avg = 0;
              if (docs.isNotEmpty) {
                var total = 0;
                for (final d in docs) total += (d.data()['rating'] as int?) ?? 0;
                avg = total / docs.length;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Rating: ${avg.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('(${docs.length} review${docs.length == 1 ? '' : 's'})', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (docs.isEmpty) const Text('No reviews yet.'),
                  ...docs.map((d) {
                    final rd = d.data();
                    final reviewer = (rd['reviewerName'] ?? '').toString();
                    final rtext = (rd['text'] ?? '').toString();
                    final rating = (rd['rating'] as int?) ?? 0;
                    final created = rd['createdAt'];
                    String when = '';
                    if (created is Timestamp) {
                      final dt = created.toDate();
                      when = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text((reviewer.isEmpty ? 'U' : reviewer.substring(0,1)).toUpperCase())),
                      title: Row(children: [Text(reviewer.isEmpty ? '(User)' : reviewer), const SizedBox(width: 8), ...List.generate(rating, (_) => const Icon(Icons.star, size: 14, color: Colors.amber))]),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (rtext.isNotEmpty) Text(rtext), if (when.isNotEmpty) Text(when, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                    );
                  }).toList(),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Leave a review', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _starSelector(),
          TextField(controller: _textCtrl, minLines: 2, maxLines: 5, decoration: const InputDecoration(hintText: 'Share your experience')),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _submitting ? null : () => _submitReview(widget.userId),
                child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Review'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  // show items donated by this user
                  Navigator.push(context, MaterialPageRoute(builder: (_) => _DonorItemsList(userId: widget.userId)));
                },
                child: const Text('View donated items'),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _DonorItemsList extends StatelessWidget {
  final String userId;
  const _DonorItemsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    final service = ItemService();
    return Scaffold(
      appBar: AppBar(title: const Text('Donated items')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Remove orderBy to avoid index requirement - items will still display
        stream: FirebaseFirestore.instance.collection('items').where('ownerId', isEqualTo: userId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No items yet'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final d = docs[i].data();
              return ListTile(
                leading: (d['imageUrl'] ?? '').toString().isNotEmpty ? Image.network((d['imageUrl'] ?? '').toString(), width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.image_not_supported_outlined),
                title: Text((d['title'] ?? '').toString()),
                subtitle: Text('Posted: ${service.formatTimestamp(d['createdAt'])}'),
              );
            },
          );
        },
      ),
    );
  }
}
