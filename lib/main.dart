import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_profile.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check saved login state
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('bikeparkgo_logged_in') ?? false;
  final userJsonStr = prefs.getString('bikeparkgo_user');

  UserProfile? savedProfile;
  if (isLoggedIn && userJsonStr != null) {
    try {
      savedProfile = UserProfile.fromJson(jsonDecode(userJsonStr));
    } catch (_) {
      savedProfile = null;
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: BikeParkGoApp(initialProfile: savedProfile),
    ),
  );
}

class BikeParkGoApp extends StatelessWidget {
  final UserProfile? initialProfile;

  const BikeParkGoApp({super.key, this.initialProfile});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      title: 'BikeParkGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dayTheme,
      darkTheme: AppTheme.nightTheme,
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: initialProfile != null
          ? HomeScreen(userProfile: initialProfile!)
          : const AuthScreen(),
    );
  }
}

