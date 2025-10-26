// lib/src/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Stream reviews for a donor (ordered newest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReviewsForDonor(String donorId) {
    return _db
        .collection('reviews')
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Submit a review for a donor. Requires logged in user.
  Future<void> submitReview({
    required String donorId,
    required int rating,
    String? text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in to leave a review');

    final reviewerName = user.displayName ?? '';

    await _db.collection('reviews').add({
      'donorId': donorId,
      'rating': rating,
      'text': (text ?? '').trim(),
      'reviewerId': user.uid,
      'reviewerName': reviewerName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Return a simple aggregated snapshot (average + count). This reads the reviews once.
  Future<Map<String, dynamic>> fetchRatingSummary(String donorId) async {
    final q = await _db
        .collection('reviews')
        .where('donorId', isEqualTo: donorId)
        .get();
    final docs = q.docs;
    if (docs.isEmpty) return {'avg': 0.0, 'count': 0};
    var total = 0;
    for (final d in docs) {
      total += (d.data()['rating'] as int?) ?? 0;
    }
    return {'avg': total / docs.length, 'count': docs.length};
  }
}
