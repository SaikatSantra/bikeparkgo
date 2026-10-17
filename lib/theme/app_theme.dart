import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _prefKey = 'bikeparkgo_dark_mode';
  bool _isDarkMode = true; // Default to festive Durga Puja night mode

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDarkMode);
  }
}

class AppTheme {
  // Day / Light Festive Theme (Marigold Yellow, Kash-Phool Cream & Crimson)
  static final ThemeData dayTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFDF9),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFB91C1C),       // Sindoor Red
      secondary: Color(0xFFD97706),     // Deep Marigold
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSurface: Color(0xFF1E293B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF991B1B),
      foregroundColor: Color(0xFFFEF08A),
      elevation: 3,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFDE68A), width: 1.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB91C1C),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // Night / Dark Festive Theme (Midnight Puja Sky, Glowing Gold & Sindoor Crimson)
  static final ThemeData nightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF090D16),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFDC2626),       // Glowing Crimson
      secondary: Color(0xFFF59E0B),     // Glowing Amber
      surface: Color(0xFF131A2A),
      onPrimary: Colors.white,
      onSurface: Color(0xFFF8FAFC),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF450A0A),
      foregroundColor: Color(0xFFFDE68A),
      elevation: 4,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF131A2A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x40F59E0B), width: 1.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

