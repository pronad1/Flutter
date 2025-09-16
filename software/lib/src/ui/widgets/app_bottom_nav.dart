import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared bottom navigation used across Home / Role / Search / Edit / Profile
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  /// 0=Home, 1=Role/Admin, 2=Search, 3=Edit, 4=Profile
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final role = ((snap.data?.data() ?? {})['role'] ?? '').toString();
        final roleTitle = _rolePretty(role).isEmpty ? 'Role' : _rolePretty(role);

        return NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _goToTab(context, i, role),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.volunteer_activism_outlined),
              selectedIcon: const Icon(Icons.volunteer_activism_rounded),
              label: roleTitle, // Admin / Donor / Seeker / Role
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

  void _goToTab(BuildContext context, int index, String role) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        final r = role.trim().toLowerCase();
        if (r == 'admin') {
          Navigator.pushNamed(context, '/admin-approval');
        } else if (r == 'donor') {
          Navigator.pushNamed(context, '/donor');
        } else if (r == 'seeker') {
          Navigator.pushNamed(context, '/seeker');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No role set yet. Please edit your profile.')),
          );
        }
        break;
      case 2:
        Navigator.pushNamed(context, '/search');
        break;
      case 3:
        Navigator.pushNamed(context, '/edit-profile');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  String _rolePretty(String roleRaw) {
    final r = roleRaw.trim().toLowerCase();
    if (r == 'donor') return 'Donor';
    if (r == 'seeker') return 'Seeker';
    if (r == 'admin') return 'Admin';
    return '';
  }
}
