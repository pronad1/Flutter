import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 8),
          Center(child: Text('Home Screen')),
          SizedBox(height: 16),
          // You can replace these placeholders with your real home content
        ],
      ),
      // ✅ show the same bottom navigation as other main pages
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
