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

  @override
  void initState() {
    super.initState();

    // Fade-in animation setup
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login',
                style: TextStyle(color: Colors.green, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: const Text('Register',
                style: TextStyle(color: Colors.green, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/home', arguments: 'about');
            },
            child: const Text('About',
                style: TextStyle(color: Colors.green, fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/home', arguments: 'how_it_works');
            },
            child: const Text('How it Works',
                style: TextStyle(color: Colors.green, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],

      ),
      body: Stack(
        children: [
          screenBackground(context),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome to ReuseHub!',
                    style: head1Text(colorGreen),
                    textAlign: TextAlign.center,
                    semanticsLabel: 'Welcome message',
                  ),
                  const SizedBox(height: 16),

                  // ✅ Fade-in SVG logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SvgPicture.asset(
                      'assets/images/logo_svg.svg',
                      height: 120,
                      semanticsLabel: 'ReuseHub Logo',
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ✅ Button to proceed
                  ElevatedButton(
                    onPressed: _navigateBasedOnAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      "Get Started",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
