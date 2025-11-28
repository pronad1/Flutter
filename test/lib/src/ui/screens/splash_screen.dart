import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../services/item_service.dart';
// If theme.dart is unused here, you can remove this import safely.
// import '../../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  final _db = FirebaseFirestore.instance;
  final _itemService = ItemService();

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  void _navigateBasedOnAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user != null) {
      // User is signed in → go straight to Home and clear the stack
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      // Not signed in → go to Login (back button returns here)
      Navigator.pushNamed(context, '/login');
    }
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = (screenSize.width * 0.05).floorToDouble();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: SvgPicture.asset(
          'assets/images/logo_svg.svg',
          height: 40,
          semanticsLabel: 'Reuse Hub Logo',
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.green),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Menu',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Reuse Hub Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.app_registration),
              title: const Text('Register'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/signup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Browse Items'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_categoriesKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('How it Works'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_howItWorksKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                _scrollToSection(_aboutKey);
              },
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/images/screen-back.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      "পুরনো জিনিসে নতুন হাসি😊",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Text(
                    "বাংলাদেশের রিইউজ কমিউনিটি",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _navigateBasedOnAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("Get Started"),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _scrollToSection(_categoriesKey),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Text(
                          "Browse Items",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Posted Items Section (replacing categories)
                  Container(
                    key: _categoriesKey,
                    child: Column(
                      children: [
                        const Text(
                          "What Items Can You Reuse?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Browse available items posted by donors in your community",
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Stream items from Firestore
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _db
                              .collection('items')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Failed to load items',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            }
                            
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No items available yet. Be the first to post!',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            }

                            // Get owner IDs for batch fetching names
                            final ownerIds = docs
                                .map((e) => (e.data()['ownerId'] ?? '').toString())
                                .where((s) => s.isNotEmpty)
                                .toSet()
                                .toList();

                            return FutureBuilder<Map<String, String>>(
                              future: _itemService.getUserNames(ownerIds),
                              builder: (ctx, namesSnap) {
                                final names = namesSnap.data ?? {};
                                
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
                                    final ownerNameDoc = (d['ownerName'] ?? '').toString();
                                    
                                    var resolvedName = (ownerNameDoc.trim().isNotEmpty && 
                                        ownerNameDoc.trim() != '(No name)')
                                        ? ownerNameDoc
                                        : (names[ownerId] ?? '(No name)');
                                    
                                    final displayName = (resolvedName.trim() == '(No name)')
                                        ? (ownerId.isNotEmpty 
                                            ? 'ID:${ownerId.substring(0, min(8, ownerId.length))}' 
                                            : '(No name)')
                                        : resolvedName;

                                    return Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          // Redirect to login page when unauthenticated user clicks item
                                          Navigator.pushNamed(context, '/login');
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
                                                        child: const Icon(
                                                          Icons.image_not_supported_outlined,
                                                        ),
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
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
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
                                                          Icon(Icons.location_on, 
                                                              size: 14, 
                                                              color: Colors.red[600]),
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
                                                    if (displayName.startsWith('ID:') || 
                                                        displayName == '(No name)')
                                                      FutureBuilder<String>(
                                                        future: _itemService.getUserName(ownerId),
                                                        builder: (ctx, fb) {
                                                          final name = (fb.hasData && 
                                                              fb.data!.trim().isNotEmpty && 
                                                              fb.data! != '(No name)') 
                                                              ? fb.data! 
                                                              : displayName;
                                                          return Text(
                                                            'Donor: $name · Posted: ${_itemService.formatTimestamp(d['createdAt'])}',
                                                            style: TextStyle(
                                                              color: Colors.grey[700], 
                                                              fontSize: 12,
                                                            ),
                                                          );
                                                        },
                                                      )
                                                    else
                                                      Text(
                                                        'Donor: $displayName · Posted: ${_itemService.formatTimestamp(d['createdAt'])}',
                                                        style: TextStyle(
                                                          color: Colors.grey[700], 
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // How it works
                  Container(
                    key: _howItWorksKey,
                    child: Column(
                      children: [
                        const Text(
                          "How Reuse Hub Works",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Connect with your community to donate or request items easily and sustainably.",
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildHowItWorksStep(Icons.person_add, "Sign Up or Login",
                            "Create an account as a donor or seeker."),
                        _buildHowItWorksStep(Icons.search, "Browse or List Items",
                            "Search for items or list your donations."),
                        _buildHowItWorksStep(Icons.request_page, "Make Requests",
                            "Send requests for items you need."),
                        _buildHowItWorksStep(Icons.chat, "Connect and Exchange",
                            "Message users and arrange pickups."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // About/footer
                  Container(
                    key: _aboutKey,
                    width: double.infinity,
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.all(30),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int columns = 1;
                        if (constraints.maxWidth > 900) {
                          columns = 3;
                        } else if (constraints.maxWidth > 600) {
                          columns = 2;
                        }
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth / columns - 20,
                              child: const Text(
                                "Reuse Hub\nPromoting sustainable living by connecting communities for item reuse and reducing waste.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth / columns - 20,
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Quick Links",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      )),
                                  SizedBox(height: 10),
                                  Text("Home",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("Item Categories",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("How It Works",
                                      style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth / columns - 20,
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Contact Information",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      )),
                                  SizedBox(height: 10),
                                  Text("prosenjit1156@gmail.com",
                                      style: TextStyle(color: Colors.white70)),
                                  SizedBox(height: 20),
                                  Text("© 2025 Reuse Hub. All rights reserved.",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(
      IconData icon,
      String title,
      String description,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(description, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
