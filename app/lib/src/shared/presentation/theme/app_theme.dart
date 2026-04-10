import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Futuristic Cyber Theme Colors
  static const primaryPurple = Color(0xFFA259FF);
  static const accentBlue = Color(0xFF62D9FF);
  static const backgroundDark = Color(0xFF0A0B10);
  static const surfaceElevated = Color(0xFF1E1E2E);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E9E);
  static const occupiedRed = Color(0xFFFF5252);
  static const buttonLavender = Color(0xFFC0A0FF);
  static const availableGray = Color(0xFF4A4A58);
  
  // High-fidelity Neon accents
  static const neonCyan = Color(0xFF62D9FF);
  static const neonPurple = Color(0xFFA259FF);
  static const neonPink = Color(0xFFFF5252);
  static const neonBlue = Color(0xFF00BFFF);
  static const neonGreen = Color(0xFF00FF9D);

  // Backward compatibility constants to fix lints
  static const primaryColor = primaryPurple;
  static const accentColor = accentBlue;
  static const backgroundColor = backgroundDark;
  static const surfaceColor = surfaceElevated;

  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8E24AA), Color(0xFFA555F7)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: accentBlue,
        surface: surfaceElevated,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryPurple;
          return Colors.grey.shade700;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryPurple.withOpacity(0.3);
          return Colors.black26;
        }),
      ),
    );
  }
}
