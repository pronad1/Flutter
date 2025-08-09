import 'dart:async';
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

    _navigateBasedOnAuth();
  }

  void _navigateBasedOnAuth() {
    Timer(const Duration(seconds: 5), () {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // User not logged in
        Navigator.pushReplacementNamed(context, '/register');
      } else {
        // User logged in
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
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
        backgroundColor: Colors.white, // or any color you like
        elevation: 0,
        title: const Text(
          'ReuseHub',
          style: TextStyle(color: Colors.green),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: const Text(
              'Register',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
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

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}