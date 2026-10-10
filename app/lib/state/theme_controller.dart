import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app theme state (Light, Dark, or System) and persists user preference.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _loadThemeMode();
  }

  static const String _keyThemeMode = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_keyThemeMode);
      if (savedIndex != null && savedIndex >= 0 && savedIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedIndex];
        notifyListeners();
      }
    } catch (_) {
      // Fallback to system default if SharedPreferences is unavailable
    }
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentIsDark = isDarkMode(context);
    await setThemeMode(currentIsDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, mode.index);
    } catch (_) {}
  }
}
