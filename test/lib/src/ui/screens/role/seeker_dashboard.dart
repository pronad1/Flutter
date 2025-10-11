import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_bottom_nav.dart';

class SeekerDashboard extends StatefulWidget {
  const SeekerDashboard({super.key});

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard> {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _myRequests() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    // No orderBy → no composite index required
    return _db.collection('requests').where('seekerId', isEqualTo: uid).snapshots();
  }

  DateTime _ts(dynamic v) =>
      (v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0));

  /// Batch fetch items by IDs (10 per query because of Firestore whereIn limit).
  Future<Map<String, Map<String, dynamic>>> _loadItemsByIds(
      List<String> ids) async {
    final Map<String, Map<String, dynamic>> out = {};
    const chunk = 10;
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.sublist(i, (i + chunk).clamp(0, ids.length));
      final q = await _db
          .collection('items')
          .where(FieldPath.documentId, whereIn: part)
          .get();

      for (final d in q.docs) {
        out[d.id] = d.data();
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seeker Dashboard')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _myRequests(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text(snap.error.toString(),
                  style: const TextStyle(color: Colors.red));
            }
            if (!snap.hasData) return const LinearProgressIndicator();

            // Sort newest first (client side)
            final reqDocs = snap.data!.docs.toList()
              ..sort((a, b) =>
                  _ts(b.data()['createdAt']).compareTo(_ts(a.data()['createdAt'])));

            if (reqDocs.isEmpty) {
              return const Text('No requests yet.');
            }

            // Collect the itemIds used in these requests
            final itemIds = <String>{
              for (final d in reqDocs) (d.data()['itemId'] ?? '').toString()
            }.where((e) => e.isNotEmpty).toList();

            // Batch-fetch the items for those IDs
            return FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: _loadItemsByIds(itemIds),
              builder: (context, itemsSnap) {
                if (itemsSnap.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final items = itemsSnap.data ?? {};

                return ListView.separated(
                  itemCount: reqDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = reqDocs[i];
                    final rd = r.data();
                    final itemId = (rd['itemId'] ?? '').toString();
                    final status = (rd['status'] ?? 'pending').toString();

                    final item = items[itemId] ?? {};
                    final title = (item['title'] ?? '(Untitled)').toString();
                    final desc = (item['description'] ?? 'No description.').toString();
                    final img = (item['imageUrl'] ?? '').toString();
                    final available = (item['available'] as bool?) ?? true;

                    return Card(
                      elevation: 0,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: img.isNotEmpty
                              ? Image.network(
                            img,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.inventory_2_outlined, size: 36),
                        ),
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Chip(
                                  label: Text('Status: $status'),
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(available ? 'Available' : 'Unavailable'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
