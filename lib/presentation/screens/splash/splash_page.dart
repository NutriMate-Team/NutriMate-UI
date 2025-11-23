import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main_screen.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../intro/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Get SharedPreferences to check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    
    // Get auth provider to check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Navigate based on app state
    if (authProvider.token != null) {
      // User is authenticated, go to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (!seenOnboarding) {
      // User hasn't seen onboarding, go to onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // User is not authenticated, go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Layer: Full screen thumbnail image
          Image.asset(
            'assets/images/thumbnail.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          // Foreground Layer: Centered logo
          Center(
            child: Image.asset(
              'assets/images/nutrimate_logo.png',
            ),
          ),
        ],
      ),
    );
  }
}

