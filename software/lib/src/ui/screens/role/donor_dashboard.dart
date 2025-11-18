import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_bottom_nav.dart';
import '../../widgets/chatbot/chatbot_wrapper.dart';
import '../../../services/item_service.dart';
import '../../../models/item.dart';
import '../profile/public_profile_screen.dart';

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

  // ----- Stream for requests I made (as a seeker) -----
  Stream<QuerySnapshot<Map<String, dynamic>>> _myRequestsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('requests')
        .where('seekerId', isEqualTo: _uid)
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
    final theme = Theme.of(context);
    
    return ChatbotWrapper(
      showChatbot: false, // Disabled because we have Post Item button
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
        title: const Text('My Donations'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Post new item',
            onPressed: () => Navigator.pushNamed(context, '/create-item'),
          ),
        ],
      ),
      body: SafeArea(
        child: _uid == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Please sign in to view your items',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'My Items',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No items yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start sharing by posting your first item',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/create-item'),
                            icon: const Icon(Icons.add),
                            label: const Text('Post Item'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Preload owner names for all visible docs (faster than per-item fetch)
                final ownerIds = docs.map((e) => (e.data()['ownerId'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().toList();

                return FutureBuilder<Map<String, String>>(
                  future: _itemService.getUserNames(ownerIds),
                  builder: (ctx, namesSnap) {
                    final names = namesSnap.data ?? {};
                    return Column(
                      children: docs.map((d) {
                        final m = d.data();
                        final id = d.id;
                        final title = _s(m['title']);
                        final desc = _s(m['description']);
                        final img = _s(m['imageUrl']);
                        final available = (m['available'] as bool?) ?? true;
                        final oid = (m['ownerId'] ?? '').toString();
                        final ownerName = (m['ownerName'] ?? '').toString();
                        final displayName = ownerName.trim().isNotEmpty && ownerName.trim() != '(No name)'
                            ? ownerName
                            : (names[oid] ?? '(No name)');

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/edit-item',
                                arguments: id,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image with better styling
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: img.isNotEmpty
                                          ? Image.network(
                                        img,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                          : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title.isEmpty ? '(Untitled)' : title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          desc.isEmpty
                                              ? 'No description.'
                                              : desc,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),

                                      // If displayName is placeholder, try client-side read
                                      if (displayName.trim() == '(No name)' || displayName.startsWith('ID:'))
                                        FutureBuilder<String>(
                                          future: _itemService.getUserName(oid),
                                          builder: (ctx2, fb2) {
                                            final n = (fb2.hasData && fb2.data!.trim().isNotEmpty && fb2.data! != '(No name)') ? fb2.data! : displayName;
                                            return Text('Donor: $n · Posted: ${_itemService.formatTimestamp(m['createdAt'])}', style: TextStyle(color: Colors.grey[700], fontSize: 12));
                                          },
                                        )
                                      else
                                        Text(
                                          'Donor: $displayName · Posted: ${_itemService.formatTimestamp(m['createdAt'])}',
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                      // Show seeker name if item has been received
                                      FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                        future: FirebaseFirestore.instance
                                            .collection('requests')
                                            .where('itemId', isEqualTo: id)
                                            .where('status', isEqualTo: 'approved')
                                            .limit(1)
                                            .get(),
                                        builder: (ctx3, reqSnap) {
                                          if (reqSnap.connectionState != ConnectionState.done || !reqSnap.hasData || reqSnap.data!.docs.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          final req = reqSnap.data!.docs.first.data();
                                          final seekerId = (req['seekerId'] ?? '').toString();
                                          if (seekerId.isEmpty) return const SizedBox.shrink();
                                          return FutureBuilder<String>(
                                            future: _itemService.getUserName(seekerId),
                                            builder: (ctx4, seekerSnap) {
                                              final seekerName = (seekerSnap.hasData && seekerSnap.data!.trim().isNotEmpty && seekerSnap.data! != '(No name)')
                                                  ? seekerSnap.data!
                                                  : 'ID:${seekerId.substring(0, seekerId.length > 8 ? 8 : seekerId.length)}';
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  children: [
                                                    Text('Received by: ', style: TextStyle(color: Colors.blueGrey[700], fontSize: 12, fontStyle: FontStyle.italic)),
                                                    InkWell(
                                                      onTap: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => PublicProfileScreen(userId: seekerId),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        seekerName,
                                                        style: TextStyle(
                                                          color: Colors.blue[700],
                                                          fontSize: 12,
                                                          fontStyle: FontStyle.italic,
                                                          decoration: TextDecoration.underline,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      Row(
                                        children: [
                                          FutureBuilder<bool>(
                                            future: _itemService.hasApprovedRequestsForItem(id),
                                            builder: (ctx, snap) {
                                              final hasApproved = snap.data == true;
                                              final isAvail = !hasApproved && available;
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isAvail ? Colors.green.shade50 : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: isAvail ? Colors.green.shade200 : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isAvail ? Icons.check_circle : Icons.cancel,
                                                      size: 16,
                                                      color: isAvail ? Colors.green.shade700 : Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      isAvail ? 'Available' : 'Unavailable',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: isAvail ? Colors.green.shade700 : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
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
                                            icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                                            style: IconButton.styleFrom(
                                              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        );
                      }).toList(),
                    );
                  },
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

                        final seekerId = _s(m['seekerId']);

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: leading,
                            title: Text(titleText),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: $status'),
                                if (seekerId.isNotEmpty)
                                  FutureBuilder<String>(
                                    future: _itemService.getUserName(seekerId),
                                    builder: (ctx2, seekerSnap) {
                                      final seekerName = (seekerSnap.hasData && seekerSnap.data!.trim().isNotEmpty && seekerSnap.data! != '(No name)')
                                          ? seekerSnap.data!
                                          : 'Unknown seeker';
                                      return Row(
                                        children: [
                                          Text('From: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          InkWell(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PublicProfileScreen(userId: seekerId),
                                              ),
                                            ),
                                            child: Text(
                                              seekerName,
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 12,
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
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

            const SizedBox(height: 24),
            // Info card to navigate to Seeker History
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue[200]!),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/seeker-history'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Requested Items',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track items you have requested',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-item'),
        icon: const Icon(Icons.add),
        label: const Text('Post Item'),
        elevation: 4,
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
