// lib/src/services/item_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'supabase_image_service.dart';
import '../models/item.dart';

class ItemService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // You can switch to an 'items' bucket later if you create it + add policies.
  final _img = SupabaseImageService(bucket: 'avatars');

  /// Create item with optional image
  Future<String> createItem({
    required String title,
    required String description,
    XFile? imageFile,
    String? category,
    String? condition,
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
      available: true,
      createdAt: Timestamp.now(), // kept for your model; we'll also write serverTimestamp below
    ).toMap()
      ..['titleLower'] = title.trim().toLowerCase();


    // ➕ ensure fields needed by search/sorting exist even if Item model doesn't have them
    item['titleLower'] = title.trim().toLowerCase();
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

    await _db.collection('requests').add({
      'itemId': itemId,
      'ownerId': ownerId,
      'seekerId': user.uid,
      'status': 'pending', // pending | approved | rejected | completed
      'createdAt': FieldValue.serverTimestamp(),
    });
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

    await ref.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If donor approves a request, mark the item as unavailable.
    if (status == 'approved') {
      final reqSnap = await ref.get();
      final reqData = reqSnap.data();
      final itemId = reqData?['itemId'] as String?;
      if (itemId != null && itemId.isNotEmpty) {
        await _db.collection('items').doc(itemId).update({'available': false, 'updatedAt': FieldValue.serverTimestamp()});
      }
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
}
