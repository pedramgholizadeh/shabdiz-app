import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Liquid Glass theme — Netflix-grade dark cinematic surfaces with
/// Apple-tv style frosted glass layers.
class GlassTheme {
  // Palette: midnight charcoal + neon rose accent (netflix-red × apple-blue)
  static const Color bgDeep = Color(0xFF07070B);
  static const Color bgSurface = Color(0xFF101018);
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);
  static const Color accent = Color(0xFFE50914); // netflix rose
  static const Color accentSecondary = Color(0xFF0A84FF); // apple blue
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textMuted = Color(0xFF8E8EA0);

  static ThemeData darkTheme() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgDeep,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accentSecondary,
        surface: bgSurface,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: bgSurface.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: _inputTheme(),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.25),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.06)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgSurface,
        contentTextStyle: GoogleFonts.vazirmatn(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData lightTheme() {
    // Light is kept minimal — the app is designed dark-first.
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F4F8),
      colorScheme: base.colorScheme.copyWith(primary: accent, secondary: accentSecondary),
      textTheme: _textTheme(base.textTheme, dark: false),
      inputDecorationTheme: _inputTheme(dark: false),
    );
  }

  static TextTheme _textTheme(TextTheme base, {bool dark = true}) {
    final vazir = GoogleFonts.vazirmatnTextTheme(base);
    return vazir.apply(
      bodyColor: dark ? textPrimary : const Color(0xFF14141A),
      displayColor: dark ? textPrimary : const Color(0xFF14141A),
    );
  }

  static InputDecorationTheme _inputTheme({bool dark = true}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.12)),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
      hintStyle: TextStyle(color: textMuted),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  static LinearGradient get heroScrim => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, bgDeep],
      );

  static LinearGradient get accentGradient => const LinearGradient(
        colors: [Color(0xFFE50914), Color(0xFFFF6B5E)],
      );
}
