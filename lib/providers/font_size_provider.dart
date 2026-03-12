import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Optional: for persistence

class FontSizeProvider with ChangeNotifier {
  static const String _key = 'font_scale';
  double _scaleFactor = 1.0;

  double get scaleFactor => _scaleFactor;

  FontSizeProvider() {
    _loadSavedScale(); // Load preference on init
  }

  // Scale a base font size
  double scale(double baseSize) => baseSize * _scaleFactor;

  // Update scale + persist
  Future<void> setScaleFactor(double factor) async {
    _scaleFactor = factor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, factor);
  }

  // Load saved preference
  Future<void> _loadSavedScale() async {
    final prefs = await SharedPreferences.getInstance();
    _scaleFactor = prefs.getDouble(_key) ?? 1.0;
    notifyListeners(); // Trigger rebuild after load
  }

  // Preset options for UI
  static const List<double> presetScales = [0.8, 1.0, 1.2, 1.5];
  static const List<String> presetLabels = ['Small', 'Default', 'Large', 'Extra Large'];
}