// lib/src/services/item_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'supabase_image_service.dart';
import 'request_limit_service.dart';
import '../models/item.dart';

class ItemService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // You can switch to an 'items' bucket later if you create it + add policies.
  final _img = SupabaseImageService(bucket: 'avatars');
  final _requestLimitService = RequestLimitService();

  /// Create item with optional image
  Future<String> createItem({
    required String title,
    required String description,
    XFile? imageFile,
    String? category,
    String? condition,
    String? pickupAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ref = _db.collection('items').doc();
    String? imageUrl;
    String? imagePath;

    if (imageFile != null) {
      final up = await _img.uploadItemImage(
        uid: user.uid,
        itemId: ref.id,
        file: imageFile,
      );
      imageUrl = up.publicUrl;
      imagePath = up.path;
    }

    final item = Item(
      id: ref.id,
      ownerId: user.uid,
      title: title.trim(),
      description: description.trim(),
      imageUrl: imageUrl,
      imagePath: imagePath,
      category: category,
      condition: condition,
      pickupAddress: pickupAddress,
      available: true,
      createdAt: Timestamp.now(), // kept for your model; we'll also write serverTimestamp below
    ).toMap()
      ..['titleLower'] = title.trim().toLowerCase();


    // ➕ ensure fields needed by search/sorting exist even if Item model doesn't have them
    item['titleLower'] = title.trim().toLowerCase();
    // Denormalize owner name for easy reads in non-admin contexts
    String ownerName = user.displayName ?? '';
    try {
      if (ownerName.isEmpty) {
        final u = await _db.collection('users').doc(user.uid).get();
        final ud = u.data();
        if (ud != null) ownerName = (ud['name'] ?? ud['displayName'] ?? '').toString();
      }
    } catch (_) {
      // ignore
    }
    item['ownerName'] = ownerName.trim();
    item['createdAt'] = FieldValue.serverTimestamp();

    await ref.set(item);
    return ref.id;
  }

  /// Update item fields; optionally replace image
  Future<void> updateItem({
    required String itemId,
    String? title,
    String? description,
    String? category,
    String? condition,
    String? pickupAddress,
    bool? available,
    XFile? newImageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ref = _db.collection('items').doc(itemId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Item not found');

    final d = snap.data() as Map<String, dynamic>;
    if (d['ownerId'] != user.uid) {
      throw Exception('You can only edit your own item');
    }

    String? imageUrl = d['imageUrl'];
    String? imagePath = d['imagePath'];

    if (newImageFile != null) {
      final up = await _img.uploadItemImage(
        uid: user.uid,
        itemId: itemId,
        file: newImageFile,
      );
      final newUrl = up.publicUrl;
      final newPath = up.path;

      if (imagePath != null && imagePath != newPath) {
        await _img.deleteIfExists(imagePath);
      }

      imageUrl = newUrl;
      imagePath = newPath;
    }

    final update = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      if (title != null) 'titleLower': title.trim().toLowerCase(), // <-- for search
      if (description != null) 'description': description.trim(),
      if (category != null) 'category': category,
      if (condition != null) 'condition': condition,
      if (pickupAddress != null) 'pickupAddress': pickupAddress.trim(),
      if (available != null) 'available': available,
      if (newImageFile != null) 'imageUrl': imageUrl,
      if (newImageFile != null) 'imagePath': imagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await ref.update(update);
  }

  /// Get one item
  Future<Item> getItemById(String itemId) async {
    final snap = await _db.collection('items').doc(itemId).get();
    if (!snap.exists) throw Exception('Item not found');
    return Item.fromDoc(snap);
  }

  /// Feed
  Stream<List<Item>> streamLatest({int limit = 50}) {
    return _db
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Item.fromDoc(d)).toList());
  }

  // ---------------- Requests ----------------

  /// Seeker → request an item
  Future<void> createRequest({
    required String itemId,
    required String ownerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Check monthly request limit
    final limitInfo = await _requestLimitService.checkRequestLimit();
    if (!(limitInfo['canRequest'] as bool)) {
      final current = limitInfo['currentCount'] as int;
      final limit = limitInfo['limit'] as int;
      throw Exception('Monthly request limit reached ($current/$limit). Please try again next month.');
    }

    // Prevent duplicate requests from the same seeker for same item
    final existing = await _db
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('seekerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You have already requested this item');
    }

    // Check item availability and whether an approved request already exists
    final itemRef = _db.collection('items').doc(itemId);
    final itemSnap = await itemRef.get();
    if (!itemSnap.exists) throw Exception('Item not found');
    final itemData = itemSnap.data() as Map<String, dynamic>;
    final isAvailable = (itemData['available'] as bool?) ?? true;
    if (!isAvailable) throw Exception('Item is not available');

    // Note: don't query other users' requests here — security rules may forbid
    // reading requests that don't belong to the current user. Rely on the
    // item's `available` field to determine if requests are allowed.

    await _db.collection('requests').add({
      'itemId': itemId,
      'ownerId': ownerId,
      'seekerId': user.uid,
      'status': 'pending', // pending | approved | rejected | completed
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment monthly request count
    await _requestLimitService.incrementRequestCount();
  }

  /// Donor: incoming requests for my items
  Stream<QuerySnapshot<Map<String, dynamic>>> streamIncomingRequestsForOwner() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db
        .collection('requests')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Seeker: my requests
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRequestsForSeeker() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db
        .collection('requests')
        .where('seekerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Donor: update request status
  Future<void> setRequestStatus({
    required String requestId,
    required String status, // approved | rejected | completed
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ref = _db.collection('requests').doc(requestId);
    final snap = await ref.get();
    final data = snap.data();

    if (data == null || data['ownerId'] != user.uid) {
      throw Exception('Not allowed');
    }

    // If approving, do transactionally: update this request to approved and set item.available = false.
    if (status == 'approved') {
      final itemId = (data['itemId'] ?? '').toString();
      if (itemId.isEmpty) throw Exception('Invalid request: missing itemId');

      final itemRef = _db.collection('items').doc(itemId);

      await _db.runTransaction((tx) async {
        final reqSnap = await tx.get(ref);
        final reqData = reqSnap.data();
        if (reqData == null) throw Exception('Request not found');
        if (reqData['ownerId'] != user.uid) throw Exception('Not allowed');

        // Ensure item still exists and is available
        final itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) throw Exception('Item not found');
        final itemData = itemSnap.data() as Map<String, dynamic>;
        final isAvailable = (itemData['available'] as bool?) ?? true;
        if (!isAvailable) throw Exception('Item is already unavailable');

        tx.update(ref, {'status': status, 'updatedAt': FieldValue.serverTimestamp()});
        tx.update(itemRef, {'available': false, 'updatedAt': FieldValue.serverTimestamp()});
      });

      // After transaction, best-effort reject other pending requests for this item
      try {
        final pendingQ = await _db
            .collection('requests')
            .where('itemId', isEqualTo: itemId)
            .where('status', isEqualTo: 'pending')
            .get();

        final batch = _db.batch();
        for (final d in pendingQ.docs) {
          if (d.id == requestId) continue;
          batch.update(d.reference, {'status': 'rejected', 'updatedAt': FieldValue.serverTimestamp()});
        }
        if (pendingQ.docs.isNotEmpty) await batch.commit();
      } catch (_) {
        // ignore
      }
    } else {
      await ref.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Return the request status for the current user on the given item (or null)
  Future<String?> getUserRequestStatusForItem(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final q = await _db
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('seekerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['status'] ?? '').toString();
  }

  /// Return true if there is any pending request for this item
  Future<bool> hasPendingRequestsForItem(String itemId) async {
    final q = await _db
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  /// Return true if there is any approved request for this item
  Future<bool> hasApprovedRequestsForItem(String itemId) async {
    final q = await _db
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  // ----- User helpers -----
  final Map<String, String> _userNameCache = {};

  /// Get a user's display name (cached). Falls back to 'No name' when missing.
  Future<String> getUserName(String uid) async {
    if (uid.isEmpty) return '(No name)';
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      // First try publicProfiles (publicly readable)
      final publicSnap = await _db.collection('publicProfiles').doc(uid).get();
      if (publicSnap.exists) {
        final publicData = publicSnap.data();
        if (publicData != null && publicData['name'] != null) {
          final name = publicData['name'].toString().trim();
          if (name.isNotEmpty) {
            _userNameCache[uid] = name;
            return name;
          }
        }
      }
      
      // Fallback to users collection (may fail due to permissions)
      final snap = await _db.collection('users').doc(uid).get();
      final d = snap.data();
      String name = '';
      if (d != null) {
        name = (d['name'] ?? d['displayName'] ?? '').toString();
      }
      if (name.isEmpty) name = '(No name)';
      _userNameCache[uid] = name;
      return name;
    } catch (_) {
      return '(No name)';
    }
  }

  /// Batch fetch user display names for multiple uids.
  /// Returns a map uid -> displayName. Uses cache and queries missing uids in chunks.
  Future<Map<String, String>> getUserNames(List<String> uids) async {
    final out = <String, String>{};
    final toFetch = <String>[];

    for (final u in uids) {
      if (u.isEmpty) continue;
      if (_userNameCache.containsKey(u)) {
        out[u] = _userNameCache[u]!;
      } else {
        toFetch.add(u);
      }
    }

    const chunk = 10;
    try {
      for (var i = 0; i < toFetch.length; i += chunk) {
        final part = toFetch.sublist(i, (i + chunk).clamp(0, toFetch.length));
        final q = await _db.collection('users').where(FieldPath.documentId, whereIn: part).get();
        for (final d in q.docs) {
          final uid = d.id;
          final data = d.data();
          String name = (data['name'] ?? data['displayName'] ?? '').toString();
          if (name.isEmpty) name = '(No name)';
          _userNameCache[uid] = name;
          out[uid] = name;
        }
        // For any uids not returned (missing users), mark as '(No name)'
        for (final uid in part) {
          if (!out.containsKey(uid)) {
            out[uid] = '(No name)';
            _userNameCache[uid] = '(No name)';
          }
        }
      }
    } catch (_) {
      // On failure, ensure all requested uids have at least a placeholder
      for (final uid in toFetch) {
        out[uid] = '(No name)';
      }
    }

    return out;
  }

  /// Format a Firestore Timestamp or DateTime into a simple YYYY-MM-DD string.
  String formatTimestamp(dynamic t) {
    DateTime dt;
    if (t is Timestamp) dt = t.toDate();
    else if (t is DateTime) dt = t;
    else dt = DateTime.fromMillisecondsSinceEpoch(0);
    final d = dt.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Backfill `ownerName` on existing items.
  /// Returns the number of documents updated.
  /// onProgress, if provided, will be called with human readable status updates.
  Future<int> backfillOwnerNames({int pageSize = 200, void Function(String)? onProgress}) async {
    int updated = 0;
    try {
      Query<Map<String, dynamic>> q = _db.collection('items').orderBy('createdAt').limit(pageSize);
      DocumentSnapshot? last;

      while (true) {
        Query<Map<String, dynamic>> pageQ = q;
        if (last != null) pageQ = pageQ.startAfterDocument(last);
        final snap = await pageQ.get();
        if (snap.docs.isEmpty) break;
        last = snap.docs.last;

        final batch = _db.batch();
        for (final d in snap.docs) {
          final data = d.data();
          final ownerId = (data['ownerId'] ?? '').toString();
          final ownerName = (data['ownerName'] ?? '').toString();
          if (ownerId.isEmpty) continue;
          if (ownerName.isNotEmpty) continue; // already populated

          String name = '(No name)';
          try {
            final u = await _db.collection('users').doc(ownerId).get();
            final ud = u.data();
            if (ud != null) {
              name = (ud['name'] ?? ud['displayName'] ?? '').toString();
            }
            if (name.isEmpty) name = '(No name)';
          } catch (e) {
            // best-effort: if we can't read the user, leave placeholder
            name = '(No name)';
          }

          batch.update(d.reference, {'ownerName': name, 'updatedAt': FieldValue.serverTimestamp()});
          updated++;
          if (onProgress != null) onProgress('Prepared update for item ${d.id} -> $name');
        }

        // commit batch if there are writes queued
        try {
          await batch.commit();
          if (onProgress != null) onProgress('Committed ${snap.docs.length} items (processed so far: $updated)');
        } catch (e) {
          if (onProgress != null) onProgress('Failed to commit batch: $e');
        }

        if (snap.docs.length < pageSize) break;
      }
    } catch (e) {
      // propagate or return what we have
      rethrow;
    }
    return updated;
  }
}
