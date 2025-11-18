// lib/src/ui/screens/profile/public_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/review_service.dart';
import '../../../services/item_service.dart';
import '../../widgets/chatbot/chatbot_wrapper.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String? itemId; // Optional: Show this specific item prominently
  const PublicProfileScreen({super.key, required this.userId, this.itemId});

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

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }
    
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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

    // Validate rating
    if (_selectedRating < 1 || _selectedRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating (1-5 stars)')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await _reviewService.submitReview(donorId: donorId, rating: _selectedRating, text: _textCtrl.text);
      _textCtrl.clear();
      setState(() => _selectedRating = 0); // Reset rating
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted successfully!')));
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
    final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString();
    final avatar = (data['photoUrl'] ?? data['profilePicUrl'] ?? '').toString();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If itemId is provided, show the clicked item prominently
          if (widget.itemId != null) ...[
            _buildClickedItemCard(),
            const SizedBox(height: 16),
          ],
          
          // Donor Profile Card
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with avatar
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                        backgroundColor: Colors.blue.shade100,
                        child: avatar.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.blue)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name.isEmpty ? 'Donor' : name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Rating
                      FutureBuilder<Map<String, dynamic>>(
                        future: _reviewService.fetchRatingSummary(widget.userId),
                        builder: (ctx, ratSnap) {
                          if (!ratSnap.hasData) return const SizedBox.shrink();
                          final avgRating = (ratSnap.data?['avg'] ?? 0.0) as double;
                          final count = (ratSnap.data?['count'] ?? 0) as int;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(5, (i) {
                                if (i < avgRating.floor()) {
                                  return const Icon(Icons.star, size: 20, color: Colors.amber);
                                } else if (i < avgRating.ceil() && avgRating % 1 != 0) {
                                  return const Icon(Icons.star_half, size: 20, color: Colors.amber);
                                } else {
                                  return const Icon(Icons.star_border, size: 20, color: Colors.amber);
                                }
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${avgRating.toStringAsFixed(1)} ($count)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          bio,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Contact Buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Contact Donor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Display phone number
                      if (phone.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.phone, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Phone Number',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Display email
                      if (email.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email Address',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      Row(
                        children: [
                          // Phone Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: phone.isNotEmpty
                                  ? () => _makePhoneCall(phone)
                                  : null,
                              icon: const Icon(Icons.phone, size: 20),
                              label: const Text('Call'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Email Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: email.isNotEmpty
                                  ? () => _sendEmail(email)
                                  : null,
                              icon: const Icon(Icons.email, size: 20),
                              label: const Text('Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (phone.isEmpty && email.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Contact information not available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Reviews Section
          Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reviews & Ratings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _reviewService.streamReviewsForDonor(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      final errorMsg = snapshot.error.toString();
                      final needsIndex = errorMsg.contains('index') || 
                                        errorMsg.contains('Index') ||
                                        errorMsg.contains('FAILED_PRECONDITION');
                      
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: needsIndex ? Colors.orange[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: needsIndex ? Colors.orange.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              needsIndex ? Icons.build_outlined : Icons.error_outline,
                              size: 48,
                              color: needsIndex ? Colors.orange : Colors.red,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              needsIndex 
                                  ? 'Database Index Building...' 
                                  : 'Error Loading Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: needsIndex ? Colors.orange[900] : Colors.red[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              needsIndex
                                  ? 'The Firestore index is being created. This usually takes a few minutes. Please refresh the page in a moment.'
                                  : 'Unable to load reviews at this time.',
                              style: TextStyle(
                                color: needsIndex ? Colors.orange[800] : Colors.red[800],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (needsIndex) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Refresh by rebuilding the widget
                                  if (mounted) setState(() {});
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No reviews yet', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    final reviews = snapshot.data!.docs;
                    
                    if (reviews.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No reviews yet', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: reviews.map((doc) {
                        try {
                          final data = doc.data();
                          final reviewerName = data['reviewerName'] ?? 'Anonymous';
                          final rating = (data['rating'] ?? 0) as int;
                          // Ensure rating is between 0 and 5 to avoid index errors
                          final safeRating = rating.clamp(0, 5);
                          final text = data['text'] ?? '';
                          final createdAt = data['createdAt'] as Timestamp?;
                          
                          // Safe way to get first character for avatar
                          final avatarLetter = reviewerName.isNotEmpty 
                              ? reviewerName[0].toUpperCase() 
                              : 'A';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        avatarLetter,
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reviewerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(5, (i) {
                                              return Icon(
                                                i < safeRating ? Icons.star : Icons.star_border,
                                                size: 16,
                                                color: Colors.amber,
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (createdAt != null)
                                      Text(
                                        '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                if (text.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                        } catch (e) {
                          // If there's an error rendering a single review, show error card
                          debugPrint('Error rendering review: $e');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            color: Colors.red[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[700]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Error displaying review',
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Leave a Review Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave a Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(child: _starSelector()),
                const SizedBox(height: 16),
                TextField(
                  controller: _textCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this donor...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : () => _submitReview(widget.userId),
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(_submitting ? 'Submitting...' : 'Submit Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _DonorItemsList(userId: widget.userId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('All Items'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickedItemCard() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _db.collection('items').doc(widget.itemId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        if (!snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final item = snapshot.data!.data()!;
        final title = item['title'] ?? 'No Title';
        final description = item['description'] ?? '';
        final category = item['category'] ?? 'Uncategorized';
        final condition = item['condition'] ?? 'Not specified';
        final imageUrl = item['imageUrl'] ?? '';
        final available = item['available'] as bool? ?? true;

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Item You\'re Viewing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: available ? Colors.white : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        available ? 'Available' : 'Donated',
                        style: TextStyle(
                          color: available ? Colors.green.shade700 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Item Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 40),
                                );
                              },
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip(Icons.category, category, Colors.blue),
                              _buildInfoChip(Icons.info_outline, condition, Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
