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
