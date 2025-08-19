// lib/src/ui/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  bool _busy = false;

  // 🛡️ Hard-coded admin (dev shortcut)
  static const String _hardcodedAdminEmail = 'ug2102049@cse.pstu.ac.bd';

  bool get _isHardcodedAdmin =>
      (auth.currentUser?.email ?? '').toLowerCase() == _hardcodedAdminEmail;

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
      setState(() {});
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ➜ If hardcoded admin, you can auto-open the admin panel.
    //    Uncomment this block if you want immediate redirect.
    /*
    if (_isHardcodedAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/admin-approval');
      });
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      // Not logged in → send to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If hardcoded admin, ignore emailVerified/approved checks entirely.
    final emailVerified = _isHardcodedAdmin ? true : auth.currentUser!.emailVerified;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isHardcodedAdmin ? 'Admin Profile' : 'My Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          // For hardcoded admin, we’ll still try to show profile data if present,
          // but we won’t block UI if missing.
          if (!_isHardcodedAdmin && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_isHardcodedAdmin && snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!_isHardcodedAdmin &&
              (!snapshot.hasData || !(snapshot.data?.exists ?? false))) {
            return const Center(child: Text('No profile data found.'));
          }

          final data = snapshot.data?.data() ?? {};
          final name = (data['name'] ?? (_isHardcodedAdmin ? 'Super Admin' : '')) as String;
          final email = (data['email'] ?? auth.currentUser!.email ?? '') as String;
          final photo = (data['profilePicUrl'] ?? '') as String;

          // If hardcoded admin, force these values
          final approved = _isHardcodedAdmin ? true : (data['approved'] as bool?) ?? false;
          final isAdmin = _isHardcodedAdmin ? true : (data['isAdmin'] as bool?) ?? false;
          final role = _isHardcodedAdmin ? 'Admin' : (data['role'] as String?) ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔔 Show verification banner ONLY for non-admins
                if (!_isHardcodedAdmin && !emailVerified)
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

                const SizedBox(height: 8),

                CircleAvatar(
                  radius: 50,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person, size: 50) : null,
                ),
                const SizedBox(height: 16),

                Text(
                  name.isEmpty ? '(${'No name'})' : name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                Text(email, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),

                // Role + Approval + Email status chips
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
                      label: Text(approved ? 'Approved' : 'Pending approval'),
                      avatar: Icon(
                        approved ? Icons.verified : Icons.hourglass_bottom,
                        size: 18,
                        color: approved ? Colors.green : null,
                      ),
                    ),
                    Chip(
                      label: Text(emailVerified ? 'Email verified' : 'Email not verified'),
                      avatar: Icon(
                        emailVerified ? Icons.mark_email_read : Icons.mark_email_unread,
                        size: 18,
                        color: emailVerified ? Colors.green : null,
                      ),
                    ),
                    if (_isHardcodedAdmin) // visual hint
                      const Chip(
                        label: Text('Hardcoded Admin'),
                        avatar: Icon(Icons.admin_panel_settings, size: 18),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔐 Admin-only access (hardcoded admin OR Firestore admin)
                if (_isHardcodedAdmin || isAdmin)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin-approval');
                      },
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Open Admin Approval Panel'),
                      ),
                    ),
                  ),

                if (!(_isHardcodedAdmin || isAdmin))
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Access is granted after email verification and admin approval.',
                      textAlign: TextAlign.center,
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
