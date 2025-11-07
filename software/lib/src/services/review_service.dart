// lib/src/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Stream reviews for a donor (ordered newest first)
  /// If ordering fails due to missing index, falls back to unordered query
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReviewsForDonor(String donorId) {
    try {
      return _db
          .collection('reviews')
          .where('donorId', isEqualTo: donorId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      // Fallback to unordered query if index doesn't exist yet
      return _db
          .collection('reviews')
          .where('donorId', isEqualTo: donorId)
          .snapshots();
    }
  }

  /// Submit a review for a donor. Requires logged in user.
  Future<void> submitReview({
    required String donorId,
    required int rating,
    String? text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in to leave a review');

    // Validate rating is between 1 and 5
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final reviewerName = user.displayName ?? 'Anonymous';

    await _db.collection('reviews').add({
      'donorId': donorId,
      'rating': rating,
      'text': (text ?? '').trim(),
      'reviewerId': user.uid,
      'reviewerName': reviewerName.isNotEmpty ? reviewerName : 'Anonymous',
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
