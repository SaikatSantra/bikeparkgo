import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_profile.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Launch root widget synchronously so first frame is drawn in < 16ms
  // Avoid awaiting platform channels or disk reads before runApp to prevent Android launch ANR
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const BikeParkGoApp(),
    ),
  );
}

class BikeParkGoApp extends StatelessWidget {
  const BikeParkGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      title: 'BikeParkGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dayTheme,
      darkTheme: AppTheme.nightTheme,
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const StartupGateScreen(),
    );
  }
}

/// Instantaneous splash/gate screen that renders on frame 0.
/// It verifies login state safely in the background with timeout & try-catch,
/// eliminating any possibility of Android "App isn't responding" (ANR).
class StartupGateScreen extends StatefulWidget {
  const StartupGateScreen({super.key});

  @override
  State<StartupGateScreen> createState() => _StartupGateScreenState();
}

class _StartupGateScreenState extends State<StartupGateScreen> {
  @override
  void initState() {
    super.initState();
    // Allow the initial UI frame to be rasterized by Android before doing any I/O
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineInitialRoute();
    });
  }

  Future<void> _determineInitialRoute() async {
    UserProfile? savedProfile;

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('Preferences load timed out'),
      );
      final isLoggedIn = prefs.getBool('bikeparkgo_logged_in') ?? false;
      final userJsonStr = prefs.getString('bikeparkgo_user');

      if (isLoggedIn && userJsonStr != null) {
        savedProfile = UserProfile.fromJson(jsonDecode(userJsonStr));
      }
    } catch (e) {
      debugPrint('Startup check error or first launch: $e');
      savedProfile = null;
    }

    if (!mounted) return;

    // Smooth transition to destination
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => savedProfile != null
            ? HomeScreen(userProfile: savedProfile)
            : const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D16) : const Color(0xFFFFFDF9);
    final primaryColor = isDark ? const Color(0xFFDC2626) : const Color(0xFFB91C1C);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Festive Trishul & Bike Logo
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: primaryColor.withOpacity(0.15),
                      child: const Center(
                        child: Text('🔱', style: TextStyle(fontSize: 44)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'BikeParkGo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFFFDE68A) : primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '🌸 শুভ শারদীয়া • Safe Bike Parking',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 38),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
