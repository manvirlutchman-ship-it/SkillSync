import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Default to light mode (Apple Style)
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // 🟢 This triggers the rebuild of the whole app
  }
}