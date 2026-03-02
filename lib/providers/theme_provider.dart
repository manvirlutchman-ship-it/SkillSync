import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

class ThemeProvider with ChangeNotifier {
  // Default to light mode
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final v = sp.getString(_kThemeModeKey);
      if (v == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (v == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // triggers rebuild
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kThemeModeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}