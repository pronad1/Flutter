// lib/src/ui/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ✅ use the service for requests (and later you can reuse for item ops)
import '../../services/item_service.dart';

/// Home shows a feed of items.
/// - Donor: can post (FAB) but cannot request items.
/// - Seeker: cannot post; can request items.
/// - Admin: can view everything; no post button by default.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _itemService = ItemService();

  String _role = ''; // 'donor' | 'seeker' | 'admin' | ''
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final data = snap.data() ?? {};
      final role = (data['role'] ?? '').toString().toLowerCase();
      if (!mounted) return;
      setState(() {
        _role = role;
        _loadingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRole = false);
    }
  }

  /// Stream of items ordered by createdAt desc
  Stream<QuerySnapshot<Map<String, dynamic>>> _itemsStream() {
    return _db
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  bool get _canPost => _role == 'donor';   // donor only
  bool get _canRequest => _role == 'seeker'; // seeker only

  Future<void> _requestItem({
    required String itemId,
    required String ownerId,
    required String title,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first.')),
      );
      return;
    }

    // Confirm
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request this item?'),
        content: Text('You are requesting: "$title"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Request')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _itemService.createRequest(itemId: itemId, ownerId: ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to donor.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final id = docs[i].id;
              final ownerId = (d['ownerId'] ?? '').toString();
              final title = (d['title'] ?? '').toString();
              final desc = (d['description'] ?? '').toString();
              final imageUrl = (d['imageUrl'] ?? '').toString();
              final available = (d['available'] as bool?) ?? true;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Optional: item detail route if you wire it
                    // Navigator.pushNamed(context, '/item-detail', arguments: id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
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

                        // Texts + actions
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                title.isEmpty ? '(Untitled)' : title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Description
                              Text(
                                desc.isEmpty ? 'No description.' : desc,
                                style: const TextStyle(color: Colors.black87),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  // Availability chip
                                  Chip(
                                    label: Text(available ? 'Available' : 'Unavailable'),
                                    avatar: Icon(
                                      available ? Icons.check_circle : Icons.block,
                                      size: 18,
                                      color: available ? Colors.green : Colors.redAccent,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Seeker action
                                  if (_canRequest && available)
                                    TextButton.icon(
                                      onPressed: () => _requestItem(
                                        itemId: id,
                                        ownerId: ownerId,
                                        title: title,
                                      ),
                                      icon: const Icon(Icons.handshake_outlined),
                                      label: const Text('Request'),
                                    ),

                                  // Donor action (edit own item)
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
      ),

      // Donor-only FAB to post items
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
