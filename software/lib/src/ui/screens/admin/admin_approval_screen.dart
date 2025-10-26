import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/item_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/chatbot/chatbot_wrapper.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  bool _showPendingOnly = true;
  bool _isBackfilling = false;
  String _backfillLog = '';
  final _itemService = ItemService();

  /// Stream for the list (pending/all)
  Stream<QuerySnapshot<Map<String, dynamic>>> _listStream() {
    final col = FirebaseFirestore.instance.collection('users');
    // NOTE: If you don't have a createdAt field on all docs yet, you can remove orderBy temporarily.
    return _showPendingOnly
        ? col.where('approved', isEqualTo: false).orderBy('createdAt', descending: true).snapshots()
        : col.orderBy('createdAt', descending: true).limit(100).snapshots();
  }

  Future<void> _approveUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'approved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve: $e')),
      );
    }
  }

  // Safe getters
  String _str(Object? v) => (v ?? '').toString();
  String _lower(Object? v) => _str(v).toLowerCase();
  bool _bool(Object? v) => (v is bool) ? v : false;

  @override
  Widget build(BuildContext context) {
    final usersCol = FirebaseFirestore.instance.collection('users');

    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Admin – Approvals'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showPendingOnly = !_showPendingOnly),
            child: Text(
              _showPendingOnly ? 'Show All' : 'Show Pending',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ---- BACKFILL ACTION ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.backup),
                  label: Text(_isBackfilling ? 'Backfilling…' : 'Backfill owner names'),
                  onPressed: _isBackfilling
                      ? null
                      : () async {
                    setState(() {
                      _isBackfilling = true;
                      _backfillLog = 'Starting backfill...';
                    });
                    try {
                      final count = await _itemService.backfillOwnerNames(
                        onProgress: (s) {
                          setState(() {
                            _backfillLog = '${DateTime.now().toIso8601String()}: $s\n' + _backfillLog;
                          });
                        },
                      );
                      if (!mounted) return;
                      setState(() {
                        _backfillLog = 'Backfill complete — updated $count items.\n' + _backfillLog;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backfill updated $count items')));
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _backfillLog = 'Backfill failed: $e\n' + _backfillLog;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backfill failed: $e')));
                    } finally {
                      if (!mounted) return;
                      setState(() {
                        _isBackfilling = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (_backfillLog.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Text(_backfillLog, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    ),
                  ),
              ],
            ),
          ),

          // ---- COUNTS HEADER ----
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: usersCol.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load counts: ${snap.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }

              final docs = snap.data?.docs ?? const [];
              int total = docs.length;
              int donors = 0;
              int seekers = 0;

              for (final d in docs) {
                final role = _lower(d.data()['role']);
                if (role == 'donor') donors++;
                if (role == 'seeker') seekers++;
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CountChip(label: 'Total', value: total),
                    _CountChip(label: 'Donors', value: donors),
                    _CountChip(label: 'Seekers', value: seekers),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 0),

          // ---- USERS LIST ----
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _listStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading users: ${snapshot.error}\n\n'
                            'Tip: Ensure your admin user doc has isAdmin: true and rules permit admin reads.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(_showPendingOnly ? 'No pending users.' : 'No users found.'),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, i) {
                    final user = docs[i].data();
                    final uid = docs[i].id;

                    final name = _str(user['name']);
                    final email = _str(user['email']);
                    final role  = _str(user['role']);
                    final approved = _bool(user['approved']);
                    final emailVerified = _bool(user['emailVerified']);
                    final isAdmin = _bool(user['isAdmin']);

                    return ListTile(
                      title: Text(name.isEmpty ? '(No name)' : name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty) Text(email),
                          if (role.isNotEmpty) Text(role),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (emailVerified)
                                Chip(
                                  avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  label: const Text('Email verified'),
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                  labelStyle: const TextStyle(color: Colors.green),
                                ),
                              if (isAdmin)
                                Chip(
                                  avatar: const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 18),
                                  label: const Text('Admin'),
                                  backgroundColor: Colors.purple.withOpacity(0.1),
                                  labelStyle: const TextStyle(color: Colors.purple),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: approved
                          ? const Icon(Icons.verified, color: Colors.green)
                          : ElevatedButton(
                        onPressed: () => _approveUser(uid),
                        child: const Text('Approve'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ✅ Show global bottom nav here as well
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }
}

// ----- COUNTER CHIP -----
class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  const _CountChip({required this.label, required this.value});

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
