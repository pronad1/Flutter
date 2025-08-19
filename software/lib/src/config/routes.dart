// lib/src/config/routes.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/profile/profile_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/admin/admin_approval_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => SignUpScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => ProfileScreen());

    // Admin approval (gated)
      case '/admin-approval':
        return MaterialPageRoute(builder: (_) => _AdminGate());

      default:
        return MaterialPageRoute(builder: (_) => SplashScreen());
    }
  }
}

class _AdminGate extends StatelessWidget {
  _AdminGate({super.key});

  static const String _hardcodedAdminEmail = 'ug2102049@cse.pstu.ac.bd';

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Dev shortcut: allow specific email
    if ((user.email ?? '').toLowerCase() == _hardcodedAdminEmail) {
      return true;
    }

    // Normal path: check Firestore flag
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snap.data();
      final flag = (data?['isAdmin'] as bool?) ?? false;
      return flag;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return AdminApprovalScreen();
        } else {
          return _NotAuthorizedScreen();
        }
      },
    );
  }
}

class _NotAuthorizedScreen extends StatelessWidget {
  const _NotAuthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Not Authorized')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You are not authorized to view this page.'),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
