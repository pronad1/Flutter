// lib/src/services/request_limit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestLimitService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const int maxRequestsPerMonth = 4;

  /// Get the current month key (e.g., "2025-11")
  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Check if user can send a request this month
  /// Returns {canRequest: bool, currentCount: int, limit: int}
  Future<Map<String, dynamic>> checkRequestLimit() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'canRequest': false, 'currentCount': 0, 'limit': maxRequestsPerMonth, 'error': 'Not logged in'};
    }

    final monthKey = _getCurrentMonthKey();
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};

    // Get monthly request tracking
    final monthlyRequests = (data['monthlyRequests'] as Map<String, dynamic>?) ?? {};
    final currentCount = (monthlyRequests[monthKey] as int?) ?? 0;

    final canRequest = currentCount < maxRequestsPerMonth;

    return {
      'canRequest': canRequest,
      'currentCount': currentCount,
      'limit': maxRequestsPerMonth,
      'monthKey': monthKey,
    };
  }

  /// Increment request count for current month
  Future<void> incrementRequestCount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final monthKey = _getCurrentMonthKey();
    final userRef = _db.collection('users').doc(user.uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      
      if (!snapshot.exists) {
        throw Exception('User document not found');
      }

      final data = snapshot.data() ?? {};
      final monthlyRequests = Map<String, dynamic>.from((data['monthlyRequests'] as Map<String, dynamic>?) ?? {});
      
      final currentCount = (monthlyRequests[monthKey] as int?) ?? 0;
      
      if (currentCount >= maxRequestsPerMonth) {
        throw Exception('Monthly request limit reached ($maxRequestsPerMonth/$maxRequestsPerMonth)');
      }

      monthlyRequests[monthKey] = currentCount + 1;

      transaction.update(userRef, {
        'monthlyRequests': monthlyRequests,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get request stats for display
  Future<String> getRequestStatsText() async {
    final stats = await checkRequestLimit();
    final current = stats['currentCount'] as int;
    final limit = stats['limit'] as int;
    return '$current/$limit';
  }

  /// Clean up old monthly data (optional, can be called periodically)
  Future<void> cleanupOldMonths() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};
    final monthlyRequests = Map<String, dynamic>.from((data['monthlyRequests'] as Map<String, dynamic>?) ?? {});
    
    if (monthlyRequests.isEmpty) return;

    // Keep only last 3 months
    final now = DateTime.now();
    final monthsToKeep = <String>{};
    for (int i = 0; i < 3; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      monthsToKeep.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }

    final cleaned = Map<String, dynamic>.fromEntries(
      monthlyRequests.entries.where((e) => monthsToKeep.contains(e.key)),
    );

    if (cleaned.length != monthlyRequests.length) {
      await userRef.update({'monthlyRequests': cleaned});
    }
  }

  /// Get total donated items count
  Future<int> getDonatedItemsCount(String userId) async {
    final snapshot = await _db
        .collection('items')
        .where('ownerId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  /// Get total requested items count
  Future<int> getRequestedItemsCount(String userId) async {
    final snapshot = await _db
        .collection('requests')
        .where('seekerId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  /// Get comprehensive user stats
  Future<Map<String, dynamic>> getUserStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'donatedCount': 0,
        'requestedCount': 0,
        'monthlyRequestsUsed': 0,
        'monthlyRequestsLimit': maxRequestsPerMonth,
      };
    }

    final limitInfo = await checkRequestLimit();
    final donatedCount = await getDonatedItemsCount(user.uid);
    final requestedCount = await getRequestedItemsCount(user.uid);

    return {
      'donatedCount': donatedCount,
      'requestedCount': requestedCount,
      'monthlyRequestsUsed': limitInfo['currentCount'],
      'monthlyRequestsLimit': maxRequestsPerMonth,
      'canRequest': limitInfo['canRequest'],
    };
  }
}
