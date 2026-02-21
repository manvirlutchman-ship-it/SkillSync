import 'package:flutter/material.dart';

class AppTheme {
  // --- Apple Style Light Palette ---
  static const Color appleBackground = Color(0xFFF5F5F7);
  static const Color appleSlate = Color(0xFF1D1D1F); // Very dark gray, almost black
  static const Color appleGray = Color(0xFF86868B);  // Professional gray
  static const Color appleCard = Colors.white;
  static const Color appleBorder = Color(0xFFE8E8ED); // Subtle divider color

  // --- Minimalist Dark Palette ---
  static const Color darkBackground = Colors.black;
  static const Color darkSlate = Colors.white;
  static const Color darkGray = Colors.white54;
  static const Color darkCard = Color(0xFF1E1E1E);

  // ⚪ LIGHT THEME DEFINITION
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: appleBackground,

    // 🟢 THE KEY FIX: Explicitly define a monochrome color scheme
    colorScheme: const ColorScheme.light(
      primary: appleSlate,       // Primary buttons and text
      onPrimary: Colors.white,   // Text on primary buttons
      secondary: appleGray,      // Secondary text/icons
      surface: appleCard,        // Cards and input backgrounds
      onSurface: appleSlate,     // Text on cards
      outline: appleBorder,      // Borders
    ),

    // Cursor and selection color (prevents purple handles)
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: appleSlate,
      selectionColor: Color(0x331D1D1F), // 20% opacity slate
      selectionHandleColor: appleSlate,
    ),

    // 1. Global AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: appleSlate),
      titleTextStyle: TextStyle(
        color: appleSlate, 
        fontSize: 18, 
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),

    // 2. Global Button Theme (Matching the 16.0 "Rounded Square" Radius)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: appleSlate,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // 🟢 Consistent radius
        ),
        textStyle: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w700, 
          letterSpacing: -0.2,
        ),
      ),
    ),

    // 3. Global TextField Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: appleBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: appleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: appleSlate, width: 1.5),
      ),
      labelStyle: const TextStyle(color: appleGray, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: appleSlate),
    ),
  );

  // ⚫ DARK THEME (Apple Midnight Style)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black, // Pure Black background
    
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,            // White text/icons
      onPrimary: Colors.black,          // Black text on white buttons
      secondary: Color(0xFF8E8E93),     // Apple System Gray
      surface: Color(0xFF1C1C1E),       // Elevated gray (Card background)
      onSurface: Colors.white,
      outline: Color(0xFF38383A),       // Darker borders
    ),

    // Apply the same 16.0 Squircle logic globally
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF38383A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
    ),
  );
}