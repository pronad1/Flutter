import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';  // For debugPrint

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up then send email verification and mark approved=false
  Future<String?> signUp({
    required String email,
    required String password,
    required String role,            
    String? name,
    String? mobile,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return 'Unexpected error: user is null';

      // Create Firestore user profile with approved=false
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'role': role,
        'name': name ?? '',
        'mobile': mobile ?? '',
        'phone': mobile ?? '',  // Store as phone too for consistency
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approvedBy': null,
      });

      // Create public profile (minimal fields for public viewing)
      try {
        await _firestore.collection('publicProfiles').doc(user.uid).set({
          'name': name ?? '',
          'bio': '',
          'photoUrl': '',
          'profilePicUrl': '',  // Support both field names
          'email': email, // Include email for contact button
          'phone': mobile ?? '',  // Include phone for contact button
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Created publicProfiles/${user.uid} during signup');
      } catch (e) {
        debugPrint('⚠️ Could not create publicProfiles/${user.uid}: $e');
        // best-effort: don't block signup if publicProfiles write fails
      }

      // Send verification email
      await user.sendEmailVerification();

      // Sign out so the user can complete verification
      await _auth.signOut();

      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return _firebaseAuthErrorToMessage(e);
    } catch (e) {
      return 'Sign-up failed: $e';
    }
  }

  /// Login but only allow access if emailVerified && approved==true
  Future<String?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return 'Unexpected error: user is null';

      // Refresh emailVerified flag
      await user.reload();
      final freshUser = _auth.currentUser;

      if (freshUser == null) {
        await _auth.signOut();
        return 'Unexpected error: user is null after reload';
      }

      if (!freshUser.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email first. Check your inbox/spam.';
      }

      // Check admin approval
      final doc =
      await _firestore.collection('users').doc(freshUser.uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return 'Profile not found. Contact support.';
      }

      final approved = (doc.data()?['approved'] as bool?) ?? false;
      if (!approved) {
        await _auth.signOut();
        return 'Your account is pending admin approval.';
      }

      // All good
      return null;
    } on FirebaseAuthException catch (e) {
      return _firebaseAuthErrorToMessage(e);
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Helper to resend email verification (callable from UI)
  Future<String?> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return 'You are not signed in.';
    try {
      await user.sendEmailVerification();
      return null;
    } catch (e) {
      return 'Failed to send verification email: $e';
    }
  }

  String _firebaseAuthErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'User disabled. Contact support.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'Email already registered.';
      case 'weak-password':
        return 'Password too weak.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}
