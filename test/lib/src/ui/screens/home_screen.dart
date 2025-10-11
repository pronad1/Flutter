// lib/src/ui/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../../services/item_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _itemService = ItemService();

  bool get _canPost => (_auth.currentUser != null);
  bool get _canRequest => (_auth.currentUser != null);

  Stream<QuerySnapshot<Map<String, dynamic>>> _itemsStream() {
    return _db.collection('items').orderBy('createdAt', descending: true).snapshots();
  }

  String _prettyStatus(String s) {
    if (s == 'pending') return 'Requested';
    if (s == 'approved') return 'Accepted';
    return s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _requestItem({required String itemId, required String ownerId, required String title}) async {
    try {
      await _itemService.createRequest(itemId: itemId, ownerId: ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent')));
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Failed to request'),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _itemsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load items: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No items yet. Be the first to post!'));
          }

          final ownerIds = docs.map((e) => (e.data()['ownerId'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().toList();

          return FutureBuilder<Map<String, String>>(
            future: _itemService.getUserNames(ownerIds),
            builder: (ctx, namesSnap) {
              final names = namesSnap.data ?? {};
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data();
                  final id = doc.id;
                  final ownerId = (d['ownerId'] ?? '').toString();
                  final title = (d['title'] ?? '').toString();
                  final desc = (d['description'] ?? '').toString();
                  final imageUrl = (d['imageUrl'] ?? '').toString();
                  final rawAvailable = (d['available'] as bool?) ?? true;
                  final available = rawAvailable;
          final ownerNameDoc = (d['ownerName'] ?? '').toString();
          var resolvedName = (ownerNameDoc.trim().isNotEmpty && ownerNameDoc.trim() != '(No name)')
            ? ownerNameDoc
            : (names[ownerId] ?? '(No name)');
          final displayName = (resolvedName.trim() == '(No name)')
            ? (ownerId.isNotEmpty ? 'ID:${ownerId.substring(0, min(8, ownerId.length))}' : '(No name)')
            : resolvedName;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 88,
                                      height: 88,
                                      color: Colors.black12,
                                      child: const Icon(Icons.image_not_supported_outlined),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    desc.isEmpty ? 'No description.' : desc,
                                    style: const TextStyle(color: Colors.black87),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                      // If displayName is just an ID or placeholder, try a client-side read to get the real name
                                      if (displayName.startsWith('ID:') || displayName == '(No name)')
                                        FutureBuilder<String>(
                                          future: _itemService.getUserName(ownerId),
                                          builder: (ctx, fb) {
                                            final name = (fb.hasData && fb.data!.trim().isNotEmpty && fb.data! != '(No name)') ? fb.data! : displayName;
                                            return Text(
                                              'Donor: $name · Posted: ${_itemService.formatTimestamp(d['createdAt'])}',
                                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                            );
                                          },
                                        )
                                      else
                                        Text(
                                          'Donor: $displayName · Posted: ${_itemService.formatTimestamp(d['createdAt'])}',
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (_canRequest)
                                        FutureBuilder<List<Object?>>(
                                          future: Future.wait([
                                            _itemService.hasPendingRequestsForItem(id),
                                            _itemService.hasApprovedRequestsForItem(id),
                                            _itemService.getUserRequestStatusForItem(id),
                                          ]),
                                          builder: (ctx, snap2) {
                                            if (snap2.connectionState == ConnectionState.waiting) {
                                              return const SizedBox.shrink();
                                            }
                                            final hasPending = (snap2.data != null && snap2.data!.isNotEmpty && snap2.data![0] == true);
                                            final hasApproved = (snap2.data != null && snap2.data!.length > 1 && snap2.data![1] == true);
                                            final status = (snap2.data != null && snap2.data!.length > 2) ? (snap2.data![2] as String?) : null;

                                            if (hasApproved && (status == null || status.isEmpty)) {
                                              return TextButton.icon(
                                                onPressed: null,
                                                icon: const Icon(Icons.block),
                                                label: const Text('Unavailable'),
                                              );
                                            }

                                            if (hasPending && (status == null || status.isEmpty)) {
                                              return TextButton.icon(
                                                onPressed: null,
                                                icon: const Icon(Icons.hourglass_top),
                                                label: const Text('Booked'),
                                              );
                                            }

                                            if (status != null && status.isNotEmpty) {
                                              final label = status == 'pending'
                                                  ? 'Requested'
                                                  : (status == 'approved' ? 'Accepted' : _prettyStatus(status));
                                              return TextButton.icon(
                                                onPressed: null,
                                                icon: const Icon(Icons.hourglass_top),
                                                label: Text(label),
                                              );
                                            }

                                            if (available) {
                                              return TextButton.icon(
                                                onPressed: () => _requestItem(
                                                  itemId: id,
                                                  ownerId: ownerId,
                                                  title: title,
                                                ),
                                                icon: const Icon(Icons.handshake_outlined),
                                                label: const Text('Request'),
                                              );
                                            }

                                            return const SizedBox.shrink();
                                          },
                                        ),

                                      if (!_canRequest)
                                        FutureBuilder<bool>(
                                          future: _itemService.hasPendingRequestsForItem(id),
                                          builder: (ctx, pendingSnap) {
                                            final hasPending = pendingSnap.data == true;
                                            if (hasPending) {
                                              return Chip(
                                                label: const Text('Booked'),
                                                avatar: const Icon(Icons.hourglass_top, size: 18, color: Colors.orange),
                                              );
                                            }
                                            return Chip(
                                              label: Text(available ? 'Available' : 'Unavailable'),
                                              avatar: Icon(
                                                available ? Icons.check_circle : Icons.block,
                                                size: 18,
                                                color: available ? Colors.green : Colors.redAccent,
                                              ),
                                            );
                                          },
                                        ),

                                      if (_canPost && _auth.currentUser?.uid == ownerId)
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/edit-item',
                                              arguments: id,
                                            );
                                          },
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Edit'),
                                        ),
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
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      floatingActionButton: _canPost
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create-item'),
              icon: const Icon(Icons.add),
              label: const Text('Post Item'),
            )
          : null,
    );
  }
}
