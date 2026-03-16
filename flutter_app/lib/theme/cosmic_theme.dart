import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CosmicTheme {
  // ── Color Palette ──────────────────────────────────────
  static const Color deepSpace = Color(0xFF0A0E1A);
  static const Color cosmicNavy = Color(0xFF0F1629);
  static const Color nebulaPurple = Color(0xFF1A1040);
  static const Color starGold = Color(0xFFFFD700);
  static const Color saffron = Color(0xFFFF9933);
  static const Color celestialBlue = Color(0xFF4A90D9);
  static const Color moonSilver = Color(0xFFCDD6E0);
  static const Color marsRed = Color(0xFFE74C3C);
  static const Color venusGreen = Color(0xFF2ECC71);
  static const Color jupiterOrange = Color(0xFFE67E22);
  static const Color saturnBlue = Color(0xFF3498DB);
  static const Color rahuSmoke = Color(0xFF6C7A89);
  static const Color ketuBrown = Color(0xFF9B59B6);
  static const Color cardBg = Color(0xFF141A2E);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color borderGlow = Color(0xFF2A3456);

  // ── Planet Colors ──────────────────────────────────────
  static const Map<String, Color> planetColors = {
    'sun': Color(0xFFFFD700),
    'moon': Color(0xFFF5F5F5),
    'mars': Color(0xFFE74C3C),
    'mercury': Color(0xFF2ECC71),
    'jupiter': Color(0xFFE67E22),
    'venus': Color(0xFFFF69B4),
    'saturn': Color(0xFF3498DB),
    'rahu': Color(0xFF6C7A89),
    'ketu': Color(0xFF9B59B6),
  };

  // ── Rashi Colors ───────────────────────────────────────
  static const Map<String, Color> rashiColors = {
    'Aries': Color(0xFFE74C3C),
    'Taurus': Color(0xFF2ECC71),
    'Gemini': Color(0xFFF39C12),
    'Cancer': Color(0xFFF5F5F5),
    'Leo': Color(0xFFFFD700),
    'Virgo': Color(0xFF27AE60),
    'Libra': Color(0xFF3498DB),
    'Scorpio': Color(0xFFC0392B),
    'Sagittarius': Color(0xFFE67E22),
    'Capricorn': Color(0xFF34495E),
    'Aquarius': Color(0xFF2980B9),
    'Pisces': Color(0xFF9B59B6),
  };

  static Color getPlanetColor(String planet) =>
      planetColors[planet.toLowerCase()] ?? moonSilver;

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [deepSpace, cosmicNavy, nebulaPurple],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1A2038), Color(0xFF0F1629)],
  );

  // ── Theme Data ─────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepSpace,
      primaryColor: starGold,
      colorScheme: const ColorScheme.dark(
        primary: starGold,
        secondary: saffron,
        surface: cardBg,
        error: marsRed,
        onPrimary: deepSpace,
        onSecondary: deepSpace,
        onSurface: moonSilver,
      ),
      textTheme: GoogleFonts.latoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: starGold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: moonSilver),
          bodyLarge: TextStyle(fontSize: 16, color: moonSilver, height: 1.6),
          bodyMedium: TextStyle(fontSize: 14, color: moonSilver, height: 1.5),
          bodySmall: TextStyle(fontSize: 12, color: rahuSmoke),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: starGold),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.w600, color: starGold),
        iconTheme: const IconThemeData(color: starGold),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderGlow, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: starGold,
          foregroundColor: deepSpace,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: starGold,
          side: const BorderSide(color: starGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGlow)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGlow)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: starGold, width: 1.5)),
        labelStyle: const TextStyle(color: rahuSmoke),
        hintStyle: const TextStyle(color: rahuSmoke),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cosmicNavy,
        selectedItemColor: starGold,
        unselectedItemColor: rahuSmoke,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: borderGlow,
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: starGold.withOpacity(0.2),
        labelStyle: const TextStyle(color: moonSilver, fontSize: 12),
        side: const BorderSide(color: borderGlow),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
