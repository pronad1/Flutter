import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _db = FirebaseFirestore.instance;
  final _qCtrl = TextEditingController();
  Timer? _debounce;

  bool _busy = false;
  String _query = '';
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _qCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _qCtrl.text.trim();
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    if (!mounted) return;
    setState(() {
      _query = q;
      _busy = true;
      _results = [];
    });

    if (q.isEmpty) {
      setState(() => _busy = false);
      return;
    }

    final qLower = q.toLowerCase();

    try {
      // ---- FAST PATH (prefix on titleLower) ----
      // Requires items documents to have a `titleLower` field with the title in lowercase,
      // and an index on orderBy(titleLower).
      final snap = await _db
          .collection('items')
          .where('available', isEqualTo: true)
          .orderBy('titleLower')
          .startAt([qLower])
          .endAt(['$qLower\uf8ff'])
          .limit(50)
          .get();

      final rows = snap.docs.map((d) {
        final data = d.data();
        data['__id'] = d.id;
        return data;
      }).toList();

      setState(() {
        _results = rows;
        _busy = false;
      });
    } catch (e) {
      // ---- FALLBACK (client-side filter) ----
      // Works even if titleLower/index doesn’t exist yet.
      try {
        final snap = await _db
            .collection('items')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();

        final rows = snap.docs.map((d) {
          final data = d.data();
          data['__id'] = d.id;
          return data;
        }).where((m) {
          final title = (m['title'] ?? '').toString().toLowerCase();
          final desc = (m['description'] ?? '').toString().toLowerCase();
          final available = (m['available'] as bool?) ?? true;
          if (!available) return false;
          return title.contains(qLower) || desc.contains(qLower);
        }).toList();

        if (mounted) {
          setState(() {
            _results = rows;
            _busy = false;
          });
        }
      } catch (e2) {
        if (!mounted) return;
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e2')),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Items')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _qCtrl,
              decoration: InputDecoration(
                hintText: 'Search by title or description',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Results for: ${_query.isEmpty ? '(type to search)' : _query}'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? const Center(child: Text('No matches found.'))
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = _results[i];
                final id = (m['__id'] ?? '').toString();
                final title = (m['title'] ?? '').toString();
                final desc = (m['description'] ?? '').toString();
                final imageUrl = (m['imageUrl'] ?? '').toString();

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 72,
                            height: 72,
                            color: Colors.black12,
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? '(Untitled)' : title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                desc.isEmpty ? 'No description.' : desc,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
