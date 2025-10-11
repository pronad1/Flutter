// lib/src/ui/screens/role/donor_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_bottom_nav.dart';
import '../../../services/item_service.dart';
import '../../../models/item.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _itemService = ItemService();

  String? get _uid => _auth.currentUser?.uid;

  // ----- Streams (NO orderBy -> no composite index needed) -----
  Stream<QuerySnapshot<Map<String, dynamic>>> _myItemsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('items')
        .where('ownerId', isEqualTo: _uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _incomingRequestsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('requests')
        .where('ownerId', isEqualTo: _uid)
        .snapshots();
  }

  // ----- Actions on requests -----
  Future<void> _setRequestStatus({
    required String requestId,
    required String status, // 'approved' | 'rejected' | 'completed'
  }) async {
    try {
      // Use ItemService which will also update the item availability when approved
      await _itemService.setRequestStatus(requestId: requestId, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  // Helper to read safe strings
  String _s(dynamic v) => (v ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Dashboard')),
      body: _uid == null
          ? const Center(child: Text('Please sign in.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('My items'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _myItemsStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ErrorBox(error: snap.error.toString());
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  );
                }

                // sort locally by createdAt desc
                final docs = [...snap.data!.docs];
                docs.sort((a, b) {
                  final ta = a.data()['createdAt'] as Timestamp?;
                  final tb = b.data()['createdAt'] as Timestamp?;
                  final da = ta?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final db = tb?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return db.compareTo(da);
                });

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('You have not posted any items yet.'),
                  );
                }

                return Column(
                  children: docs.map((d) {
                    final m = d.data();
                    final id = d.id;
                    final title = _s(m['title']);
                    final desc = _s(m['description']);
                    final img = _s(m['imageUrl']);
                    final available = (m['available'] as bool?) ?? true;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: img.isNotEmpty
                                  ? Image.network(
                                img,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: 72,
                                height: 72,
                                color: Colors.black12,
                                child: const Icon(Icons.image),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? '(Untitled)' : title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    desc.isEmpty
                                        ? 'No description.'
                                        : desc,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(available
                                            ? 'Available'
                                            : 'Unavailable'),
                                        avatar: Icon(
                                          available
                                              ? Icons.check_circle
                                              : Icons.block,
                                          size: 18,
                                          color: available
                                              ? Colors.green
                                              : Colors.redAccent,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        tooltip: 'Edit item',
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/edit-item',
                                            arguments: id,
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 16),
            const _SectionTitle('Incoming requests'),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _incomingRequestsStream(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ErrorBox(error: snap.error.toString());
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  );
                }

                // sort locally by createdAt desc
                final reqs = [...snap.data!.docs];
                reqs.sort((a, b) {
                  final ta = a.data()['createdAt'] as Timestamp?;
                  final tb = b.data()['createdAt'] as Timestamp?;
                  final da = ta?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final db = tb?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return db.compareTo(da);
                });

                if (reqs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No incoming requests yet.'),
                  );
                }

                return Column(
                  children: reqs.map((d) {
                    final m = d.data();
                    final requestId = d.id;
                    final itemId = _s(m['itemId']);
                    final status = _s(m['status']); // pending/approved/...

                    // Load the item so we can show image + title
                    return FutureBuilder<Item>(
                      future: _itemService.getItemById(itemId),
                      builder: (ctx, itemSnap) {
                        Widget leading;
                        String titleText = 'Item: $itemId';

                        if (itemSnap.connectionState == ConnectionState.waiting) {
                          leading = const SizedBox(width: 56, height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                        } else if (itemSnap.hasError || itemSnap.data == null) {
                          leading = const Icon(Icons.inbox_outlined);
                        } else {
                          final item = itemSnap.data!;
                          titleText = item.title.isEmpty ? '(Untitled)' : item.title;
                          final img = item.imageUrl ?? '';
                          leading = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: img.isNotEmpty
                                ? Image.network(img, width: 56, height: 56, fit: BoxFit.cover)
                                : const Icon(Icons.image_not_supported_outlined, size: 36),
                          );
                        }

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: leading,
                            title: Text(titleText),
                            subtitle: Text('Status: $status'),
                            trailing: _RequestActions(
                              status: status,
                              onApprove: () => _setRequestStatus(
                                requestId: requestId,
                                status: 'approved',
                              ),
                              onReject: () => _setRequestStatus(
                                requestId: requestId,
                                status: 'rejected',
                              ),
                              onComplete: () => _setRequestStatus(
                                requestId: requestId,
                                status: 'completed',
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
        floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-item'),
        icon: const Icon(Icons.add),
        label: const Text('Post Item'),
        ),
    );
  }
}

// --- Small helpers/widgets ---

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        error,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

class _RequestActions extends StatelessWidget {
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  const _RequestActions({
    super.key,
    required this.status,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'pending') {
      return Wrap(
        spacing: 4,
        children: [
          TextButton(
            onPressed: onApprove,
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: onReject,
            child: const Text('Reject'),
          ),
        ],
      );
    }
    if (status == 'approved') {
      return TextButton(
        onPressed: onComplete,
        child: const Text('Complete'),
      );
    }
    return const SizedBox.shrink(); // rejected or completed => no actions
  }
}
