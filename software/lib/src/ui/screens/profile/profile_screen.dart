// lib/src/ui/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/chatbot/chatbot_wrapper.dart';
import '../../../services/review_service.dart';
import '../../../services/request_limit_service.dart';

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
        } else {
          _safeNav('/donor'); // All users go to donor dashboard
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

                const SizedBox(height: 12),

                // User Stats Card (Donated Items, Requested Items, Monthly Requests)
                if (!showAdminStuff)
                  FutureBuilder<Map<String, dynamic>>(
                    future: RequestLimitService().getUserStats(),
                    builder: (ctx, statsSnap) {
                      if (!statsSnap.hasData) {
                        return const SizedBox(
                          height: 60,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      
                      final stats = statsSnap.data!;
                      final donatedCount = stats['donatedCount'] as int;
                      final requestedCount = stats['requestedCount'] as int;
                      final monthlyUsed = stats['monthlyRequestsUsed'] as int;
                      final monthlyLimit = stats['monthlyRequestsLimit'] as int;
                      final canRequest = stats['canRequest'] as bool;

                      return Card(
                        elevation: 2,
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'My Activity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: canRequest ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          canRequest ? Icons.check_circle : Icons.block,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$monthlyUsed/$monthlyLimit',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => Navigator.pushNamed(context, '/donor'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: _StatColumn(
                                        icon: Icons.volunteer_activism,
                                        label: 'Donated',
                                        value: '$donatedCount',
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  Container(width: 1, height: 50, color: Colors.green.shade200),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => Navigator.pushNamed(context, '/seeker-history'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: _StatColumn(
                                        icon: Icons.request_page,
                                        label: 'Requested',
                                        value: '$requestedCount',
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Container(width: 1, height: 50, color: Colors.green.shade200),
                                  Expanded(
                                    child: _StatColumn(
                                      icon: Icons.calendar_month,
                                      label: 'This Month',
                                      value: '$monthlyUsed/$monthlyLimit',
                                      color: canRequest ? Colors.green : Colors.red,
                                      subtitle: canRequest ? 'Available' : 'Limit Reached',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap on Donated or Requested to view details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
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

                // Badges - Redesigned for better alignment
                if (!showAdminStuff)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (roleTitle.isNotEmpty)
                        _BadgeChip(icon: Icons.person_pin_circle_rounded, label: roleTitle),
                      _BadgeChip(
                        icon: approved ? Icons.verified_rounded : Icons.hourglass_bottom_rounded,
                        label: approved ? 'Approved' : 'Pending',
                        color: approved ? Colors.green : Colors.orange,
                      ),
                      _BadgeChip(
                        icon: emailVerified ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                        label: emailVerified ? 'Email Verified' : 'Email Not Verified',
                        color: emailVerified ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),

                // Admin Badges and Controls
                if (showAdminStuff) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SYSTEM ADMINISTRATOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BadgeChip(
                        icon: Icons.verified_rounded,
                        label: 'Verified Admin',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _BadgeChip(
                        icon: Icons.security,
                        label: 'Full Access',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Admin Dashboard Cards
                if (showAdminStuff) ...[
                  const _AdminDashboardSection(),
                  const SizedBox(height: 16),
                ],

                // Admin-only system stats (keep existing)
                if (showAdminStuff) const _AdminStatsCard(),

                // Professional Action Buttons (non-admin only)
                if (!showAdminStuff) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/create-item'),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Donate Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/search'),
                          icon: const Icon(Icons.search),
                          label: const Text('Find Items'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),

      // ✅ Use the shared bottom navigation so it's consistent across all main pages
      bottomNavigationBar: const AppBottomNav(currentIndex: 5),
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

class _AdminDashboardSection extends StatelessWidget {
  const _AdminDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Controls Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dashboard_customize, color: Colors.deepPurple.shade700, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Admin Controls',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _AdminActionButton(
                      icon: Icons.people_alt,
                      label: 'User Approvals',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, '/admin-approval'),
                    ),
                    _AdminActionButton(
                      icon: Icons.manage_accounts,
                      label: 'Manage Users',
                      color: Colors.orange,
                      onTap: () => Navigator.pushNamed(context, '/manage-users'),
                    ),
                    _AdminActionButton(
                      icon: Icons.inventory_2,
                      label: 'All Items',
                      color: Colors.green,
                      onTap: () => Navigator.pushNamed(context, '/all-items'),
                    ),
                    _AdminActionButton(
                      icon: Icons.analytics,
                      label: 'Analytics',
                      color: Colors.purple,
                      onTap: () => Navigator.pushNamed(context, '/analytics'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatsCard extends StatelessWidget {
  const _AdminStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final usersCol = FirebaseFirestore.instance.collection('users');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: usersCol.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load stats: ${snap.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

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
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.deepPurple.shade700, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'System Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _AdminStatCard(
                      icon: Icons.people,
                      label: 'Total Users',
                      value: total.toString(),
                      color: Colors.blue,
                    ),
                    _AdminStatCard(
                      icon: Icons.volunteer_activism,
                      label: 'Donors',
                      value: donors.toString(),
                      color: Colors.green,
                    ),
                    _AdminStatCard(
                      icon: Icons.handshake,
                      label: 'Seekers',
                      value: seekers.toString(),
                      color: Colors.orange,
                    ),
                    _AdminStatCard(
                      icon: Icons.pending_actions,
                      label: 'Pending',
                      value: pending.toString(),
                      color: Colors.red,
                    ),
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

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AdminStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
}
