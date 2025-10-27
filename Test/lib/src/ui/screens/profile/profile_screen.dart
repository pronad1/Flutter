// lib/src/ui/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/chatbot/chatbot_wrapper.dart';
import '../../../services/review_service.dart';

/// Hardcoded admin identity + hosted photo URL (as in your project)
const String kAdminEmail = 'ug2102049@cse.pstu.ac.bd';
const String kAdminPhotoUrl =
    'https://raw.githubusercontent.com/pronad1/pronad1/main/465649458_1111994083915233_1094865271827201379_n.jpg';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  bool _busy = false;
  // 0=Home, 1=Role/Admin, 2=Search, 3=Edit, 4=Profile (this screen)
  int _currentIndex = 4;

  Future<void> _signOut(BuildContext context) async {
    await auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _resendVerification() async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      setState(() => _busy = true);
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Check inbox/spam.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshEmailStatus() async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      setState(() => _busy = true);
      await user.reload();
      if (!mounted) return;
      setState(() {}); // rebuild with latest emailVerified
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goToTab({required int index, required String role}) {
    setState(() => _currentIndex = index);

    // Use pushNamed (NOT replacement) so Back returns to previous page
    switch (index) {
      case 0: // Home
        _safeNav('/home');
        break;
      case 1: // Role/Admin
        final r = role.trim().toLowerCase();
        if (r == 'admin') {
          _safeNav('/admin-approval'); // admin approval panel
        } else if (r == 'donor') {
          _safeNav('/donor');
        } else if (r == 'seeker') {
          _safeNav('/seeker');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No role set yet. Please edit your profile.')),
          );
        }
        break;
      case 2: // Search
        _safeNav('/search');
        break;
      case 3: // Edit Profile
        _safeNav('/edit-profile');
        break;
      case 4: // Profile (stay here)
        break;
    }
  }

  void _safeNav(String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final emailVerified = user.emailVerified;
    final isHardcodedAdmin = user.email?.toLowerCase() == kAdminEmail.toLowerCase();

    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
        // Keep default leading so back appears when navigated from somewhere else
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _signOut(context),
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final name = (data['name'] ?? (isHardcodedAdmin ? 'Admin' : '')).toString();
          final email = (data['email'] ?? user.email ?? '').toString();
          final bio = (data['bio'] ?? '').toString();
          final approved = (data['approved'] as bool?) ?? false;
          final role = (data['role'] ?? (isHardcodedAdmin ? 'Admin' : '')).toString();
          final photo = isHardcodedAdmin ? kAdminPhotoUrl : (data['profilePicUrl'] ?? '');

          final showAdminStuff = isHardcodedAdmin || role.toLowerCase() == 'admin';
          final roleTitle = _rolePretty(role);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              children: [
                // Email verification banner (non-admin only)
                if (!showAdminStuff && !emailVerified)
                  Card(
                    color: Colors.amber.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            'Your email is not verified yet.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _busy ? null : _resendVerification,
                                  child: const Text('Resend Email'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _busy ? null : _refreshEmailStatus,
                                  child: const Text('I Verified — Refresh'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Avatar with initials fallback
                _Avatar(photoUrl: photo, name: name),

                const SizedBox(height: 12),

                // Name & Email
                Text(
                  name.isEmpty ? '(No name)' : name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),

                const SizedBox(height: 8),

                // Rating display with stars
                FutureBuilder<Map<String, dynamic>>(
                  future: ReviewService().fetchRatingSummary(user.uid),
                  builder: (ctx, ratSnap) {
                    if (!ratSnap.hasData) {
                      return const SizedBox.shrink();
                    }
                    final data = ratSnap.data!;
                    final avgRating = (data['avg'] ?? 0.0) as double;
                    final count = (data['count'] ?? 0) as int;
                    
                    if (count == 0) {
                      return const Text(
                        '☆☆☆☆☆ No ratings yet',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      );
                    }
                    
                    // Generate star string
                    String stars = '';
                    for (int i = 1; i <= 5; i++) {
                      if (i <= avgRating.floor()) {
                        stars += '★';
                      } else if (i == avgRating.ceil() && avgRating % 1 >= 0.5) {
                        stars += '⯨'; // half star
                      } else {
                        stars += '☆';
                      }
                    }
                    
                    return Text(
                      '$stars ${avgRating.toStringAsFixed(1)} ($count)',
                      style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Bio
                Text(
                  bio.isNotEmpty ? bio : 'Sorry is Nothing without change',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                ),

                const SizedBox(height: 14),

                // Badges: role / approval / email
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (roleTitle.isNotEmpty)
                      const _BadgeChip(icon: Icons.badge_outlined, label: 'Role'),
                    if (roleTitle.isNotEmpty)
                      _BadgeChip(icon: Icons.person_pin_circle_rounded, label: roleTitle),
                    _BadgeChip(
                      icon: approved ? Icons.verified_rounded : Icons.hourglass_bottom_rounded,
                      label: approved ? 'Approved' : 'Pending',
                      color: approved ? Colors.green : null,
                    ),
                    _BadgeChip(
                      icon: emailVerified ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                      label: emailVerified ? 'Email Verified' : 'Email Not Verified',
                      color: emailVerified ? Colors.green : null,
                    ),
                    if (showAdminStuff)
                      const _BadgeChip(icon: Icons.admin_panel_settings_rounded, label: 'Admin'),
                  ],
                ),

                const SizedBox(height: 16),

                // Admin-only system stats
                if (showAdminStuff) const _AdminStatsCard(),

                const SizedBox(height: 8),

                // Quick actions
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_box_outlined),
                        title: Text(
                          role.toLowerCase() == 'donor' ? 'Post a new donation' : 'Create a request',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: navigate to create item/request screen
                        },
                      ),
                      const Divider(height: 0),
                      const ListTile(
                        leading: Icon(Icons.history_rounded),
                        title: Text('Activity history'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ✅ Use the shared bottom navigation so it's consistent across all main pages
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      ),
    );
  }

  String _rolePretty(String roleRaw) {
    final r = roleRaw.trim().toLowerCase();
    if (r == 'donor') return 'Donor';
    if (r == 'seeker') return 'Seeker';
    if (r == 'admin') return 'Admin';
    return '';
  }
}

/// --- UI helpers --------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});
  final String photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(name);

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(photoUrl));
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  String _initialsFromName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final s = parts.first;
      return s.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
    );
  }
}

/// --- Admin stats card --------------------------------------------------------

class _AdminStatsCard extends StatelessWidget {
  const _AdminStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final usersCol = FirebaseFirestore.instance.collection('users');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: usersCol.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Failed to load stats: ${snap.error}',
                  style: const TextStyle(color: Colors.red));
            }
            if (!snap.hasData) return const LinearProgressIndicator();

            final docs = snap.data!.docs;
            final total = docs.length;

            int donors = 0;
            int seekers = 0;
            int pending = 0;

            for (final d in docs) {
              final data = d.data();
              final role = (data['role'] ?? '').toString().toLowerCase();
              final approved = (data['approved'] as bool?) ?? false;
              if (role == 'donor') donors++;
              if (role == 'seeker') seekers++;
              if (!approved) pending++;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Stats', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'Total', value: total),
                    _StatChip(label: 'Donors', value: donors),
                    _StatChip(label: 'Seekers', value: seekers),
                    _StatChip(label: 'Pending', value: pending),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  const _StatChip({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
