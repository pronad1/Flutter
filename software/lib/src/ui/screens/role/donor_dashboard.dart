import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav.dart';

class SeekerDashboard extends StatelessWidget {
  const SeekerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seeker Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.list_alt_outlined),
              title: Text('My requests'),
              subtitle: Text('Track approvals & pickups'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.explore_outlined),
              title: Text('Discover nearby items'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

/// 👉 Added this widget so your routes can find `DonorDashboard`.
/// If you later create a separate donor_dashboard.dart, you can remove this.
class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('My donations'),
              subtitle: Text('Manage posted items'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Post new item'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
