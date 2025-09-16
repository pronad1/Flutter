import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Items')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBar(
              controller: _controller,
              hintText: 'Search items (e.g. chair, books, clothes)',
              leading: const Icon(Icons.search),
              onSubmitted: (q) => setState(() => _query = q.trim()),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _query.isEmpty
                ? const Center(child: Text('Type to search…'))
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text('Results for: $_query'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
