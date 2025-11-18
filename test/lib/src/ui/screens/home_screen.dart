// lib/src/ui/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/chatbot/chatbot_wrapper.dart';
import '../../services/item_service.dart';
import '../../services/request_limit_service.dart';
import 'profile/public_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _itemService = ItemService();
  final _requestLimitService = RequestLimitService();

  bool get _canPost => (_auth.currentUser != null);
  bool get _canRequest => (_auth.currentUser != null);

  // Filter states
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedLocation;
  String _sortBy = 'newest'; // newest, oldest, name

  Stream<QuerySnapshot<Map<String, dynamic>>> _itemsStream() {
    return _db.collection('items').orderBy('createdAt', descending: true).snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilters(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    var filtered = docs;

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((d) {
        final cat = (d.data()['category'] ?? '').toString();
        return cat == _selectedCategory;
      }).toList();
    }

    // Apply condition filter
    if (_selectedCondition != null && _selectedCondition != 'All') {
      filtered = filtered.where((d) {
        final cond = (d.data()['condition'] ?? '').toString();
        return cond == _selectedCondition;
      }).toList();
    }

    // Apply location filter
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered.where((d) {
        final addr = (d.data()['pickupAddress'] ?? '').toString().toLowerCase();
        return addr.contains(_selectedLocation!.toLowerCase());
      }).toList();
    }

    // Apply sorting
    if (_sortBy == 'newest') {
      filtered.sort((a, b) {
        final ta = a.data()['createdAt'] as Timestamp?;
        final tb = b.data()['createdAt'] as Timestamp?;
        final da = ta?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = tb?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) {
        final ta = a.data()['createdAt'] as Timestamp?;
        final tb = b.data()['createdAt'] as Timestamp?;
        final da = ta?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = tb?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) {
        final titleA = (a.data()['title'] ?? '').toString().toLowerCase();
        final titleB = (b.data()['title'] ?? '').toString().toLowerCase();
        return titleA.compareTo(titleB);
      });
    }

    return filtered;
  }

  String _prettyStatus(String s) {
    if (s == 'pending') return 'Requested';
    if (s == 'approved') return 'Accepted';
    return s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _requestItem({required String itemId, required String ownerId, required String title}) async {
    // Check request limit first
    final limitInfo = await _requestLimitService.checkRequestLimit();
    if (!(limitInfo['canRequest'] as bool)) {
      final current = limitInfo['currentCount'] as int;
      final limit = limitInfo['limit'] as int;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Monthly Limit Reached'),
          content: Text(
            'You have used all your requests this month ($current/$limit).\n\n'
            'Your request limit will reset next month. Please try again later.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    try {
      await _itemService.createRequest(itemId: itemId, ownerId: ownerId);
      if (!mounted) return;
      
      // Get updated stats
      final stats = await _requestLimitService.checkRequestLimit();
      final used = stats['currentCount'] as int;
      final limit = stats['limit'] as int;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent ($used/$limit requests used this month)')),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Failed to request'),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explore Items'),
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort by',
              onSelected: (value) => setState(() => _sortBy = value),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'newest', child: Row(children: [Icon(Icons.access_time, size: 20), SizedBox(width: 8), Text('Newest First')])),
                PopupMenuItem(value: 'oldest', child: Row(children: [Icon(Icons.history, size: 20), SizedBox(width: 8), Text('Oldest First')])),
                PopupMenuItem(value: 'name', child: Row(children: [Icon(Icons.sort_by_alpha, size: 20), SizedBox(width: 8), Text('Name A-Z')])),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Filter Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            icon: Icons.category,
                            label: _selectedCategory ?? 'Category',
                            onTap: () => _showCategoryFilter(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            icon: Icons.star,
                            label: _selectedCondition ?? 'Condition',
                            onTap: () => _showConditionFilter(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFilterChip(
                      icon: Icons.location_on,
                      label: _selectedLocation?.isNotEmpty == true ? _selectedLocation! : 'Location',
                      onTap: () => _showLocationFilter(),
                      fullWidth: true,
                    ),
                    if (_selectedCategory != null || _selectedCondition != null || _selectedLocation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _selectedCategory = null;
                            _selectedCondition = null;
                            _selectedLocation = null;
                          }),
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear All Filters'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _itemsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Failed to load items: ${snapshot.error}'),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data!.docs;
                    
                    // Apply filters
                    docs = _applyFilters(docs);

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory != null || _selectedCondition != null || _selectedLocation != null
                                  ? 'No items match your filters'
                                  : 'No items yet. Be the first to post!',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            if (_selectedCategory != null || _selectedCondition != null || _selectedLocation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ElevatedButton.icon(
                                  onPressed: () => setState(() {
                                    _selectedCategory = null;
                                    _selectedCondition = null;
                                    _selectedLocation = null;
                                  }),
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Clear Filters'),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    final ownerIds = docs.map((e) => (e.data()['ownerId'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().toList();

                    return FutureBuilder<Map<String, String>>(
                      future: _itemService.getUserNames(ownerIds),
                      builder: (ctx, namesSnap) {
                        final names = namesSnap.data ?? {};
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final d = doc.data();
                            final id = doc.id;
                            final ownerId = (d['ownerId'] ?? '').toString();
                            final title = (d['title'] ?? '').toString();
                            final desc = (d['description'] ?? '').toString();
                            final pickupAddress = (d['pickupAddress'] ?? '').toString();
                            final imageUrl = (d['imageUrl'] ?? '').toString();
                            final category = (d['category'] ?? '').toString();
                            final condition = (d['condition'] ?? '').toString();
                            final price = (d['price'] as num?)?.toDouble();
                            final isSelling = (d['isSelling'] as bool?) ?? false;
                            final rawAvailable = (d['available'] as bool?) ?? true;
                            final available = rawAvailable;
                            
                            // Check if item is special (Brand New + Selling + Has Price)
                            final isSpecial = isSelling && 
                                              condition == "Brand New" && 
                                              price != null && 
                                              price > 0;
                            
                            final ownerNameDoc = (d['ownerName'] ?? '').toString();
                            var resolvedName = (ownerNameDoc.trim().isNotEmpty && ownerNameDoc.trim() != '(No name)')
                                ? ownerNameDoc
                                : (names[ownerId] ?? '(No name)');
                            final displayName = (resolvedName.trim() == '(No name)')
                                ? (ownerId.isNotEmpty ? 'ID:${ownerId.substring(0, min(8, ownerId.length))}' : '(No name)')
                                : resolvedName;

                            return Card(
                              elevation: isSpecial ? 4 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isSpecial 
                                    ? BorderSide(color: Colors.amber.shade700, width: 2)
                                    : BorderSide.none,
                              ),
                              child: Stack(
                                children: [
                                  // Main content
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      // Open the donor's public profile with the clicked item
                                      if (ownerId.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PublicProfileScreen(
                                              userId: ownerId,
                                              itemId: id,
                                            ),
                                          ),
                                        );
                                      }
                                    },
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
                                                    width: 88,
                                                    height: 88,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 88,
                                                    height: 88,
                                                    color: Colors.black12,
                                                    child: const Icon(Icons.image_not_supported_outlined),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        title.isEmpty ? '(Untitled)' : title,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                      if (condition.isNotEmpty)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: _getConditionColor(condition),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            condition,
                                                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      if (category.isNotEmpty)
                                                        Text(
                                                          category,
                                                          style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w600),
                                                        ),
                                                      if (category.isNotEmpty && (isSelling || price != null))
                                                        Text(' • ', style: TextStyle(color: Colors.grey[600])),
                                                      if (isSelling && price != null && price > 0)
                                                        Text(
                                                          '৳${price.toStringAsFixed(0)}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.orange[800],
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        )
                                                      else if (isSelling)
                                                        Text(
                                                          'For Sale',
                                                          style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w600),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    desc.isEmpty ? 'No description.' : desc,
                                                    style: const TextStyle(color: Colors.black87),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (pickupAddress.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on, size: 14, color: Colors.red[600]),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            'Pickup: $pickupAddress',
                                                            style: TextStyle(
                                                              color: Colors.red[700],
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  // If displayName is just an ID or placeholder, try a client-side read to get the real name
                                                  if (displayName.startsWith('ID:') || displayName == '(No name)')
                                                    FutureBuilder<String>(
                                                      future: _itemService.getUserName(ownerId),
                                                      builder: (ctx, fb) {
                                                        final name = (fb.hasData && fb.data!.trim().isNotEmpty && fb.data! != '(No name)') ? fb.data! : displayName;
                                                        return Text(
                                                          'Donor: $name · Posted: ${_itemService.formatTimestamp(d['createdAt'])}',
                                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                                        );
                                                      },
                                                    )
                                                  else
                                                    Text(
                                                      'Donor: $displayName · Posted: ${_itemService.formatTimestamp(d['createdAt'])}',
                                                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                                    ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      if (_canRequest)
                                                        FutureBuilder<List<Object?>>(
                                                          future: Future.wait([
                                                            _itemService.hasPendingRequestsForItem(id),
                                                            _itemService.hasApprovedRequestsForItem(id),
                                                            _itemService.getUserRequestStatusForItem(id),
                                                          ]),
                                                          builder: (ctx, snap2) {
                                                            if (snap2.connectionState == ConnectionState.waiting) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            final hasPending = (snap2.data != null && snap2.data!.isNotEmpty && snap2.data![0] == true);
                                                            final hasApproved = (snap2.data != null && snap2.data!.length > 1 && snap2.data![1] == true);
                                                            final status = (snap2.data != null && snap2.data!.length > 2) ? (snap2.data![2] as String?) : null;

                                            if (hasApproved && (status == null || status.isEmpty)) {
                                              return TextButton.icon(
                                                onPressed: null,
                                                icon: const Icon(Icons.block),
                                                label: const Text('Unavailable'),
                                              );
                                            }

                                            if (hasPending && (status == null || status.isEmpty)) {
                                              return TextButton.icon(
                                                onPressed: null,
                                                icon: const Icon(Icons.hourglass_top),
                                                label: const Text('Booked'),
                                              );
                                            }

                                            if (status != null && status.isNotEmpty) {
                                              final label = status == 'pending'
                                                  ? 'Requested'
                                                  : (status == 'approved' ? 'Accepted' : _prettyStatus(status));
                                              return TextButton.icon(
                                                onPressed: null,
                                                icon: const Icon(Icons.hourglass_top),
                                                label: Text(label),
                                              );
                                            }

                                            if (available) {
                                              return TextButton.icon(
                                                onPressed: () => _requestItem(
                                                  itemId: id,
                                                  ownerId: ownerId,
                                                  title: title,
                                                ),
                                                icon: const Icon(Icons.handshake_outlined),
                                                label: const Text('Request'),
                                              );
                                            }

                                            return const SizedBox.shrink();
                                          },
                                        ),

                                      if (!_canRequest)
                                        FutureBuilder<bool>(
                                          future: _itemService.hasPendingRequestsForItem(id),
                                          builder: (ctx, pendingSnap) {
                                            final hasPending = pendingSnap.data == true;
                                            if (hasPending) {
                                              return Chip(
                                                label: const Text('Booked'),
                                                avatar: const Icon(Icons.hourglass_top, size: 18, color: Colors.orange),
                                              );
                                            }
                                            return Chip(
                                              label: Text(available ? 'Available' : 'Unavailable'),
                                              avatar: Icon(
                                                available ? Icons.check_circle : Icons.block,
                                                size: 18,
                                                color: available ? Colors.green : Colors.redAccent,
                                              ),
                                            );
                                          },
                                        ),

                                      if (_canPost && _auth.currentUser?.uid == ownerId)
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/edit-item',
                                              arguments: id,
                                            );
                                          },
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Edit'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                                    
                                    // Special item badge (floating)
                                    if (isSpecial)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.amber.shade700, Colors.orange.shade700],
                                            ),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(12),
                                              bottomLeft: Radius.circular(12),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange.withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.star, color: Colors.white, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'SPECIAL',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
        floatingActionButton: _canPost
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, '/create-item'),
                icon: const Icon(Icons.add),
                label: const Text('Post Item'),
              )
            : null,
      ),
    );
  }

  Widget _buildFilterChip({required IconData icon, required String label, required VoidCallback onTap, bool fullWidth = false}) {
    final isActive = (label != 'Category' && label != 'Condition' && label != 'Location');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.green.shade700 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _categoryTile('All', Icons.all_inclusive),
                  _categoryTile('Electronics', Icons.devices),
                  _categoryTile('Computers & Laptops', Icons.computer),
                  _categoryTile('Mobile Phones', Icons.smartphone),
                  _categoryTile('Home & Furniture', Icons.home),
                  _categoryTile('Appliances', Icons.kitchen),
                  _categoryTile('Books & Education', Icons.book),
                  _categoryTile('Sports & Fitness', Icons.sports_soccer),
                  _categoryTile('Clothing & Fashion', Icons.checkroom),
                  _categoryTile('Toys & Games', Icons.videogame_asset),
                  _categoryTile('Kitchen & Dining', Icons.restaurant),
                  _categoryTile('Tools & Hardware', Icons.build),
                  _categoryTile('Garden & Outdoor', Icons.park),
                  _categoryTile('Baby & Kids', Icons.child_care),
                  _categoryTile('Health & Beauty', Icons.spa),
                  _categoryTile('Automotive', Icons.directions_car),
                  _categoryTile('Pet Supplies', Icons.pets),
                  _categoryTile('Office Supplies', Icons.work),
                  _categoryTile('Art & Crafts', Icons.palette),
                  _categoryTile('Musical Instruments', Icons.music_note),
                  _categoryTile('Other', Icons.category),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _categoryTile(String name, IconData icon) {
    final isSelected = _selectedCategory == name;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.green : null),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() => _selectedCategory = name == 'All' ? null : name);
        Navigator.pop(context);
      },
    );
  }

  void _showConditionFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Condition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            _conditionTile('All'),
            _conditionTile('Brand New'),
            _conditionTile('Like New'),
            _conditionTile('Excellent'),
            _conditionTile('Good'),
            _conditionTile('Fair'),
            _conditionTile('Used'),
            _conditionTile('For Parts'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  ListTile _conditionTile(String name) {
    final isSelected = _selectedCondition == name;
    return ListTile(
      leading: Icon(Icons.star, color: isSelected ? Colors.green : _getConditionColor(name)),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() => _selectedCondition = name == 'All' ? null : name);
        Navigator.pop(context);
      },
    );
  }

  void _showLocationFilter() {
    final controller = TextEditingController(text: _selectedLocation);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter location (e.g., PSTU, Dhaka)',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedLocation = null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _selectedLocation = controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'brand new':
        return Colors.green;
      case 'like new':
        return Colors.lightGreen;
      case 'excellent':
        return Colors.blue;
      case 'good':
        return Colors.teal;
      case 'fair':
        return Colors.orange;
      case 'used':
        return Colors.deepOrange;
      case 'for parts':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
