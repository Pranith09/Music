import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0C0C10);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1C1C28);
  static const Color cardColor = Color(0xFF181824);
  
  static const Color accent = Color(0xFF3B82F6);       // Classic Blue Accent
  static const Color accentGlow = Color(0xFF60A5FA);
  static const Color primary = Color(0xFF8B5CF6);      // Retro Violet
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color dividerColor = Color(0xFF222230);
  static const Color favoriteRed = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: primary,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accent, width: 3),
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
