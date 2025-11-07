// lib/src/ui/widgets/app_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/routes.dart';

/// Shared bottom navigation used across Home / Role / Search / Edit / Profile
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    this.currentIndex,
  });

  /// 0=Home, 1=Role/Admin, 2=Search, 3=Edit, 4=Profile
  /// If null, we’ll try to infer from the current route.
  final int? currentIndex;

  static const _routeIndex = <String, int>{
    Routes.home: 0,
    Routes.donor: 1,
    Routes.seeker: 1,
    Routes.adminApproval: 1,
    Routes.search: 2,
    Routes.editProfile: 3,
    Routes.profile: 4,
  };

  @override
  Widget build(BuildContext context) {
    // Hide the bottom nav on auth/splash routes
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    const hideOn = {Routes.splash, Routes.login, Routes.signup};
    if (hideOn.contains(routeName)) return const SizedBox.shrink();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Not signed in → don't show the bar
      return const SizedBox.shrink();
    }

    // Compute a safe selected index
    final inferredIndex = _routeIndex[routeName];
    final selectedIndex = (currentIndex ?? inferredIndex ?? 0).clamp(0, 4);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const {};
        final roleRaw = (data['role'] ?? '').toString();
        // All users get "Donor" label (since everyone can donate and request)
        final roleTitle = 'Donor';

        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) =>
              _goToTab(context, i, roleRaw, currentRoute: routeName),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.volunteer_activism_outlined),
              selectedIcon: const Icon(Icons.volunteer_activism_rounded),
              label: roleTitle, // Always "Donor" for all users
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            const NavigationDestination(
              icon: Icon(Icons.edit_outlined),
              selectedIcon: Icon(Icons.edit_rounded),
              label: 'Edit',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }

  void _goToTab(
      BuildContext context,
      int index,
      String role, {
        required String currentRoute,
      }) {
    String targetRoute = currentRoute;

    switch (index) {
      case 0:
        targetRoute = Routes.home;
        break;
      case 1:
        // All users go to donor dashboard (which will show both donated & requested items)
        final r = role.trim().toLowerCase();
        if (r == 'admin') {
          targetRoute = Routes.adminApproval;
        } else {
          targetRoute = Routes.donor; // Everyone gets donor dashboard
        }
        break;
      case 2:
        targetRoute = Routes.search;
        break;
      case 3:
        targetRoute = Routes.editProfile;
        break;
      case 4:
        targetRoute = Routes.profile;
        break;
    }

    if (targetRoute == currentRoute) return; // avoid duplicate navigation
    Navigator.pushNamedAndRemoveUntil(context, targetRoute, (r) => false);
  }

  String _rolePretty(String roleRaw) {
    final r = roleRaw.trim().toLowerCase();
    if (r == 'donor') return 'Donor';
    if (r == 'seeker') return 'Seeker';
    if (r == 'admin') return 'Admin';
    return '';
  }
}
