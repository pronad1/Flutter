// lib/src/ui/screens/seeker_history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/chatbot/chatbot_wrapper.dart';
import '../../services/item_service.dart';
import '../../models/item.dart';
import 'profile/public_profile_screen.dart';

class SeekerHistoryScreen extends StatefulWidget {
  const SeekerHistoryScreen({super.key});

  @override
  State<SeekerHistoryScreen> createState() => _SeekerHistoryScreenState();
}

class _SeekerHistoryScreenState extends State<SeekerHistoryScreen> {
  final _db = FirebaseFirestore.instance;
  final _itemService = ItemService();
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> _myRequestsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('requests')
        .where('seekerId', isEqualTo: _uid)
        .snapshots();
  }

  String _s(dynamic v) => (v ?? '').toString();

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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Requested Items'),
          elevation: 0,
        ),
        body: _uid == null
            ? const Center(child: Text('Please sign in.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _myRequestsStream(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading requests: ${snap.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Sort by createdAt desc
                  final reqDocs = [...snap.data!.docs];
                  reqDocs.sort((a, b) {
                    final ta = a.data()['createdAt'] as Timestamp?;
                    final tb = b.data()['createdAt'] as Timestamp?;
                    final da = ta?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final db = tb?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return db.compareTo(da);
                  });

                  if (reqDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No Requested Items Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse items and send requests to get started',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Summary stats
                  final pending = reqDocs.where((d) => (d.data()['status'] ?? '') == 'pending').length;
                  final approved = reqDocs.where((d) => (d.data()['status'] ?? '') == 'approved').length;
                  final rejected = reqDocs.where((d) => (d.data()['status'] ?? '') == 'rejected').length;
                  final completed = reqDocs.where((d) => (d.data()['status'] ?? '') == 'completed').length;

                  return Column(
                    children: [
                      // Summary Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.green.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _SummaryChip(label: 'Pending', count: pending, color: Colors.orange),
                            _SummaryChip(label: 'Approved', count: approved, color: Colors.green),
                            _SummaryChip(label: 'Rejected', count: rejected, color: Colors.red),
                            _SummaryChip(label: 'Completed', count: completed, color: Colors.blue),
                          ],
                        ),
                      ),

                      // List of requests
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: reqDocs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = reqDocs[i];
                            final rd = r.data();
                            final itemId = _s(rd['itemId']);
                            final status = _s(rd['status']);
                            final createdAt = (rd['createdAt'] as Timestamp?)?.toDate();

                            return FutureBuilder<Item>(
                              future: _itemService.getItemById(itemId),
                              builder: (ctx, itemSnap) {
                                if (itemSnap.connectionState == ConnectionState.waiting) {
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: const ListTile(
                                      leading: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      title: Text('Loading...'),
                                    ),
                                  );
                                }

                                if (itemSnap.hasError || !itemSnap.hasData) {
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.error_outline, size: 30),
                                      ),
                                      title: Text('Item: $itemId'),
                                      subtitle: const Text('Failed to load item details'),
                                    ),
                                  );
                                }

                                final item = itemSnap.data!;
                                final img = item.imageUrl ?? '';
                                final ownerId = item.ownerId;

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: ownerId.isNotEmpty
                                        ? () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PublicProfileScreen(userId: ownerId),
                                              ),
                                            )
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Item Image
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
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
                                                    child: const Icon(Icons.inventory_2_outlined, size: 40),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Item Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title.isEmpty ? '(Untitled)' : item.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.description.isEmpty ? 'No description.' : item.description,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                                ),
                                                const SizedBox(height: 8),

                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(status).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: _statusColor(status), width: 1.5),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(_statusIcon(status), size: 16, color: _statusColor(status)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        status.toUpperCase(),
                                                        style: TextStyle(
                                                          color: _statusColor(status),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(height: 8),

                                                // Owner Info
                                                if (ownerId.isNotEmpty)
                                                  FutureBuilder<String>(
                                                    future: _itemService.getUserName(ownerId),
                                                    builder: (ctx2, ownerSnap) {
                                                      final ownerName = (ownerSnap.hasData &&
                                                              ownerSnap.data!.trim().isNotEmpty &&
                                                              ownerSnap.data! != '(No name)')
                                                          ? ownerSnap.data!
                                                          : 'Unknown donor';
                                                      return Row(
                                                        children: [
                                                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Owner: ',
                                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              ownerName,
                                                              style: TextStyle(
                                                                color: Colors.blue[700],
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),

                                                // Request Date
                                                if (createdAt != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Requested: ${_formatDate(createdAt)}',
                                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
