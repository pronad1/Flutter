import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
              title: const Text('Categories'),
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
                      "Share, Reuse, Sustain:",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Text(
                    "Your Community Reuse Platform",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Reuse Hub connects donors and seekers to exchange reusable goods for free, "
                        "promoting sustainability and reducing waste in your community.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                          "Browse Categories",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Categories
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
                          "From electronics to clothing, find or donate items in these categories",
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            _buildCategoryCard(Icons.phone_android, "Electronics",
                                "Phones, tablets, laptops and gadgets"),
                            _buildCategoryCard(Icons.kitchen, "Appliances",
                                "Kitchen and home appliances"),
                            _buildCategoryCard(Icons.pedal_bike, "Bicycles",
                                "Bikes, scooters and transport"),
                            _buildCategoryCard(Icons.checkroom, "Clothing",
                                "Garments, shoes and accessories"),
                            _buildCategoryCard(Icons.chair, "Furniture",
                                "Tables, chairs and home fixtures"),
                            _buildCategoryCard(Icons.headphones, "Audio",
                                "Speakers, headphones and equipment"),
                            _buildCategoryCard(Icons.coffee, "Kitchenware",
                                "Utensils, machines and tools"),
                            _buildCategoryCard(Icons.build, "Tools",
                                "Garden tools, DIY equipment"),
                          ],
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
                                  Text("support@reusehub.com",
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

  Widget _buildCategoryCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
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
