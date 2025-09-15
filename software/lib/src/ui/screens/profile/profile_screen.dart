// lib/src/ui/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔑 Hardcoded admin identity + Google Drive photo (direct link)
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
      setState(() {}); // rebuild to reflect latest emailVerified
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final emailVerified = user.emailVerified;
    final isHardcodedAdmin = user.email?.toLowerCase() == kAdminEmail.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final name = (data['name'] ?? (isHardcodedAdmin ? 'Admin' : '')).toString();
          final email = (data['email'] ?? user.email).toString();
          final bio = (data['bio'] ?? '').toString();
          final approved = (data['approved'] as bool?) ?? false;
          final role = (data['role'] ?? (isHardcodedAdmin ? 'Admin' : '')).toString();
          final photo = isHardcodedAdmin
              ? kAdminPhotoUrl
              : (data['profilePicUrl'] ?? '');

          final showAdminStuff = isHardcodedAdmin || role.toLowerCase() == 'admin';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Email verification banner for users
                if (!showAdminStuff && !emailVerified)
                  Card(
                    color: Colors.amber.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                                child: ElevatedButton(
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

                // Profile avatar
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                  photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),

                const SizedBox(height: 16),

                // Name & Email
                Text(
                  name.isEmpty ? '(No name)' : name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                if (bio.isNotEmpty)
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                const SizedBox(height: 16),

                // Role + approval + email verified chips
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (role.isNotEmpty)
                      Chip(
                        label: Text(role),
                        avatar: const Icon(Icons.badge, size: 18),
                      ),
                    Chip(
                      label: Text(approved ? 'Approved' : 'Pending'),
                      avatar: Icon(
                        approved ? Icons.verified : Icons.hourglass_bottom,
                        size: 18,
                        color: approved ? Colors.green : null,
                      ),
                    ),
                    Chip(
                      label: Text(emailVerified ? 'Email Verified' : 'Email Not Verified'),
                      avatar: Icon(
                        emailVerified ? Icons.mark_email_read : Icons.mark_email_unread,
                        size: 18,
                        color: emailVerified ? Colors.green : null,
                      ),
                    ),
                    if (showAdminStuff)
                      const Chip(
                        label: Text('Admin'),
                        avatar: Icon(Icons.admin_panel_settings, size: 18),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Admin stats
                if (showAdminStuff)
                  _AdminStatsCard(),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/edit-profile');
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (showAdminStuff)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin-approval'),
                      icon: const Icon(Icons.verified_user),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Open Admin Approval Panel'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Admin stats card
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
              return Text(
                'Failed to load stats: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              );
            }
            if (!snap.hasData) {
              return const LinearProgressIndicator();
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
                const Text(
                  'System Stats',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
