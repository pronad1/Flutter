import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../style/style.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/register');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
          semanticsLabel: 'ReuseHub Logo',
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
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: const Text(
                'ReuseHub Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
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
                Navigator.pushNamed(context, '/register');
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
          screenBackground(context),
          SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Landing Page
                  Text(
                    "Fix Don't Replace:",
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "Smart Repair Partner",
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "ReuseHub helps you repair your items instead of throwing them away. Our AI guides you through the repair process, step by step, saving money and reducing waste.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _navigateBasedOnAuth,
                        style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Start Repairing Now"),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _scrollToSection(_categoriesKey),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green)),
                        child: const Text(
                          "View Repair Categories",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Categories Section
                  Container(
                    key: _categoriesKey,
                    child: Column(
                      children: [
                        Text(
                          "What Can We Help You Fix?",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "From electronics to clothing, we're here to help you repair and reuse",
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
                                "Phones, tablets, laptops and other devices"),
                            _buildCategoryCard(Icons.kitchen, "Appliances",
                                "Kitchen and home appliances"),
                            _buildCategoryCard(Icons.pedal_bike, "Bicycles",
                                "Bikes, e-bikes and personal transport"),
                            _buildCategoryCard(Icons.checkroom, "Clothing",
                                "Garment repairs, alterations and upcycling"),
                            _buildCategoryCard(Icons.chair, "Furniture",
                                "Wooden furniture, upholstery and fixtures"),
                            _buildCategoryCard(Icons.headphones, "Audio",
                                "Headphones, speakers and audio equipment"),
                            _buildCategoryCard(Icons.coffee, "Kitchen",
                                "Coffee machines, blenders and tools"),
                            _buildCategoryCard(Icons.build, "Tools",
                                "Power tools, garden equipment"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // How It Works Section
                  Container(
                    key: _howItWorksKey,
                    child: Column(
                      children: [
                        Text(
                          "How ReuseHub Works",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Our AI-powered platform makes it easy to repair instead of replace, saving you money and helping the environment.",
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildHowItWorksStep(Icons.chat, "Describe Your Problem",
                            "Tell our AI assistant what's broken and what symptoms you're experiencing."),
                        _buildHowItWorksStep(Icons.search, "Get Diagnosis",
                            "Our AI analyzes the issue and provides a likely diagnosis."),
                        _buildHowItWorksStep(Icons.list, "Follow Repair Steps",
                            "Receive step-by-step instructions with images."),
                        _buildHowItWorksStep(Icons.check_circle, "Fix & Celebrate",
                            "Successfully repair your item and extend its life."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Footer/About Section
                  Container(
                    key: _aboutKey,
                    width: double.infinity,
                    color: const Color(0xFF1A1A1A), // dark background
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
                                "ReuseHub\nMaking repairs accessible to everyone through AI guidance, reducing waste and saving resources.",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70),
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
                                          color: Colors.white)),
                                  SizedBox(height: 10),
                                  Text("Home",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("Repair Categories",
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
                                          color: Colors.white)),
                                  SizedBox(height: 10),
                                  Text("prosenjit1156@gmail.com",
                                      style: TextStyle(color: Colors.white70)),
                                  SizedBox(height: 20),
                                  Text("© 2025 ReuseHub. All rights reserved.",
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 12)),
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
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksStep(
      IconData icon, String title, String description) {
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
