// core/theme/app_theme.dart
// Material 3 ThemeData for Chal.AI.
// High-contrast green/white agritech palette designed for outdoor sunlight readability.
// Uses Inter (Google Fonts) for clean, modern typography.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Seed & Color Palette ────────────────────────────────────────────────
  static const Color _seedGreen = Color(0xFF1B7A3F); // Deep agritech green
  static const Color _primaryGreen = Color(0xFF22A157); // Vivid leaf green
  // ignore: unused_field
  static const Color _primaryLight = Color(0xFF4DC97A); // Lighter accent
  static const Color primaryLightColor = Color(0xFF4DC97A); // Public alias
  static const Color _surfaceLight = Color(0xFFF5FBF7); // Off-white tint
  static const Color _surfaceDark = Color(0xFF0D1F15); // Deep forest dark

  // Semantic colors used across the app
  static const Color healthyGreen = Color(0xFF22C55E);
  static const Color brokenRed = Color(0xFFEF4444);
  static const Color discoloredAmber = Color(0xFFF59E0B);
  static const Color integrityBlue = Color(0xFF3B82F6);

  // ─── Text Theme (Inter) ──────────────────────────────────────────────────
  static TextTheme _buildTextTheme(bool dark) {
    final base = GoogleFonts.interTextTheme();
    final color = dark ? Colors.white : const Color(0xFF0A1F14);
    final secondaryColor =
        dark ? Colors.white60 : const Color(0xFF4B6E58);

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          color: color, fontWeight: FontWeight.w800, letterSpacing: -1.5),
      displayMedium: base.displayMedium?.copyWith(
          color: color, fontWeight: FontWeight.w700, letterSpacing: -1.0),
      displaySmall: base.displaySmall?.copyWith(
          color: color, fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge?.copyWith(
          color: color, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: base.headlineMedium?.copyWith(
          color: color, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(
          color: color, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(
          color: color, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleMedium: base.titleMedium?.copyWith(
          color: color, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(
          color: secondaryColor, fontWeight: FontWeight.w500),
      bodyLarge:
          base.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w400),
      bodyMedium: base.bodyMedium?.copyWith(color: secondaryColor),
      bodySmall: base.bodySmall?.copyWith(color: secondaryColor),
      labelLarge: base.labelLarge?.copyWith(
          color: color, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: base.labelMedium?.copyWith(
          color: secondaryColor, fontWeight: FontWeight.w500),
    );
  }

  // ─── Light Theme ────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedGreen,
      brightness: Brightness.light,
      primary: _primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFB7F5CE),
      onPrimaryContainer: const Color(0xFF00391A),
      secondary: const Color(0xFF4CAF50),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFCCF0D3),
      onSecondaryContainer: const Color(0xFF00210A),
      surface: _surfaceLight,
      onSurface: const Color(0xFF0A1F14),
      surfaceContainerHighest: const Color(0xFFDCEEE3),
      error: brokenRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: _buildTextTheme(false),
      scaffoldBackgroundColor: _surfaceLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: cs.onSurface,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F5EC),
        selectedColor: _primaryGreen,
        disabledColor: Colors.grey.shade200,
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: _primaryGreen),
        secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: Colors.transparent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCEEE3), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCEEE3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8CB8A0)),
        labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4B6E58)),
      ),
      dividerTheme: const DividerThemeData(
          color: Color(0xFFDCEEE3), thickness: 1, space: 1),
      extensions: const [AppColorsExtension()],
    );
  }

  // ─── Dark Theme ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: _seedGreen,
      brightness: Brightness.dark,
      primary: _primaryLight,
      onPrimary: const Color(0xFF003919),
      primaryContainer: const Color(0xFF00531E),
      onPrimaryContainer: const Color(0xFFB7F5CE),
      secondary: const Color(0xFF6EDB8A),
      onSecondary: const Color(0xFF003919),
      surface: _surfaceDark,
      onSurface: const Color(0xFFE2F4E8),
      surfaceContainerHighest: const Color(0xFF162B1E),
      outlineVariant: const Color(0xFF2A4D38),
      error: const Color(0xFFFF8A80),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: _buildTextTheme(true),
      scaffoldBackgroundColor: _surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: cs.onSurface,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF162B1E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A3326),
        selectedColor: _primaryLight,
        disabledColor: const Color(0xFF1A3326),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: _primaryLight),
        secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF003919)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: const BorderSide(color: Colors.transparent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: const Color(0xFF003919),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: const Color(0xFF003919),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF162B1E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A4D38), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A4D38), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B7A5E)),
        labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6EDB8A)),
      ),
      dividerTheme: const DividerThemeData(
          color: Color(0xFF2A4D38), thickness: 1, space: 1),
      extensions: const [AppColorsExtension(isDark: true)],
    );
  }
}

// ─── Theme Extension for semantic colors ───────────────────────────────────
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final bool isDark;
  final Color healthy;
  final Color broken;
  final Color discolored;

  const AppColorsExtension({
    this.isDark = false,
    this.healthy = AppTheme.healthyGreen,
    this.broken = AppTheme.brokenRed,
    this.discolored = AppTheme.discoloredAmber,
  });

  @override
  AppColorsExtension copyWith({bool? isDark, Color? healthy, Color? broken, Color? discolored}) {
    return AppColorsExtension(
      isDark: isDark ?? this.isDark,
      healthy: healthy ?? this.healthy,
      broken: broken ?? this.broken,
      discolored: discolored ?? this.discolored,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) return this;
    return AppColorsExtension(
      healthy: Color.lerp(healthy, other.healthy, t)!,
      broken: Color.lerp(broken, other.broken, t)!,
      discolored: Color.lerp(discolored, other.discolored, t)!,
    );
  }
}
