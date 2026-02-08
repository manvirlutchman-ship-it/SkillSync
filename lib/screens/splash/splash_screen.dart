import 'package:flutter/material.dart';
import 'dart:async';
import 'package:skillsync/theme/app_theme.dart'; // Ensure this path is correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Start the fade-in animation slightly after the screen loads
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });

    // 2. Navigate to Home (or Login) after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Typically, you'd check if the user is logged in here.
        // For now, we keep your logic of going to /home.
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use appleSlate for the logo/text and appleBackground for the bg
    const Color appleSlate = Color(0xFF1D1D1F);

    return Scaffold(
      backgroundColor: AppTheme.appleBackground,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1000), // Smooth 1-second fade
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your App Logo (Icon)
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: appleSlate,
                  borderRadius: BorderRadius.circular(22), // Apple Squircle
                ),
                child: const Icon(
                  Icons.sync_rounded, // Choose an icon that represents "SkillSync"
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              const Text(
                'SkillSync',
                style: TextStyle(
                  color: appleSlate,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2, // Tight Apple-style tracking
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}