// lib/src/ui/screens/admin/admin_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  bool _showPendingOnly = true;

  Stream<QuerySnapshot<Map<String, dynamic>>> _query() {
    final col = FirebaseFirestore.instance.collection('users');
    return _showPendingOnly
        ? col.where('approved', isEqualTo: false).snapshots()
        : col.limit(50).snapshots();
  }

  Future<void> _approveUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'approved': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': 'admin', // set actual admin identity if you track it
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // If rules block the read, you’ll see PERMISSION_DENIED here
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
              child: Text(_showPendingOnly
                  ? 'No pending users.'
                  : 'No users found (or limited by rules / query).'),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final user = docs[i].data();
              final uid = docs[i].id;
              final name = (user['name'] ?? '') as String;
              final email = (user['email'] ?? '') as String;
              final role = (user['role'] ?? '') as String;
              final approved = (user['approved'] as bool?) ?? false;

              return ListTile(
                title: Text(name.isEmpty ? '(No name)' : name),
                subtitle: Text([email, if (role.isNotEmpty) role].join(' • ')),
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
    );
  }
}
