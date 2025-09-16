import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth & core
import '../ui/screens/admin/admin_approval_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/signup_screen.dart';
import '../ui/screens/edit_profile_screen.dart';
import '../ui/screens/profile/profile_screen.dart';
import '../ui/screens/home_screen.dart';

// Role dashboards (ALIased to avoid name conflicts)
import '../ui/screens/role/donor_dashboard.dart' as donor_screen;
import '../ui/screens/role/seeker_dashboard.dart' as seeker_screen;

// Search
import '../ui/screens/search_screen.dart';

class Routes {
  // Route name constants
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const donor = '/donor';
  static const seeker = '/seeker';
  static const search = '/search';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const adminApproval = '/admin-approval';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

    // ✅ use aliased imports to avoid class name clashes
      case donor:
        return MaterialPageRoute(builder: (_) => const donor_screen.DonorDashboard());

      case seeker:
        return MaterialPageRoute(builder: (_) => const seeker_screen.SeekerDashboard());

      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case adminApproval:
        return MaterialPageRoute(builder: (_) => const _AdminGate());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('No route defined for this page')),
          ),
        );
    }
  }
}

/// Gate that allows only admins to access AdminApprovalScreen.
/// Checks hardcoded email OR Firestore users/{uid}.isAdmin == true
class _AdminGate extends StatelessWidget {
  const _AdminGate({super.key});

  static const String _hardcodedAdminEmail = 'ug2102049@cse.pstu.ac.bd';

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Dev shortcut: allow specific email
    if ((user.email ?? '').toLowerCase() == _hardcodedAdminEmail) return true;

    try {
      final snap =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();
      return (data?['isAdmin'] as bool?) ?? false;
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return const AdminApprovalScreen();
        } else {
          return const _NotAuthorizedScreen();
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
      appBar: AppBar(title: const Text('Not Authorized')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are not authorized to view this page.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
