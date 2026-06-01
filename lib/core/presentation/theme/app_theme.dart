import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // Color Tokens
  static const brandPink = Color(0xFFFF1377);
  static const brandNavy = Color(0xFF4B176E);
  static const brandBlue = Color(0xFF6366F1); // Indigo

  // Light Mode Colors
  static const lightBg = Color(0xFFF7F9FF);
  static const lightSurface = Color(0xFFEAF2FF);
  static const lightCard = Colors.white;
  static const lightTextMuted = Color(0xFF667085);

  // Dark Mode (Premium Obsidian Slate) Colors
  static const darkBg = Color(0xFF090D16);
  static const darkSurface = Color(0xFF131926);
  static const darkCard = Color(0xFF1B2336);
  static const darkBorder = Color(0xFF28354E);
  static const darkTextMuted = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandNavy,
      brightness: Brightness.light,
    ).copyWith(
      primary: brandNavy,
      secondary: brandBlue,
      tertiary: brandPink,
      surface: lightBg,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: brandNavy,
      error: const Color(0xFFE5484D),
      surfaceContainerHigh: lightSurface,
      surfaceContainerHighest: const Color(0xFFDCE8FF),
      outline: const Color(0xFFC9D8F2),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: lightBg,
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: brandNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: brandNavy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: brandNavy, fontWeight: FontWeight.w800),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: brandNavy, fontWeight: FontWeight.w800),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: brandNavy, fontWeight: FontWeight.w800),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: brandNavy, fontWeight: FontWeight.w800),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: brandNavy, fontWeight: FontWeight.w700),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: brandNavy, fontWeight: FontWeight.w700),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: brandNavy),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: brandNavy),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: lightTextMuted),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: brandNavy, fontWeight: FontWeight.w700),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: lightTextMuted),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: lightTextMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFC9D8F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: brandBlue, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5484D)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        selectedColor: brandNavy,
        disabledColor: const Color(0xFFDCE8FF),
        labelStyle: const TextStyle(color: brandNavy, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandBlue,
          side: const BorderSide(color: Color(0xFFB8CCF6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: brandNavy,
          iconSize: 22,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDCE4F3),
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCE8FF),
        surfaceTintColor: Colors.white,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            color: selected ? brandNavy : lightTextMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? brandNavy : lightTextMuted,
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPink,
      brightness: Brightness.dark,
    ).copyWith(
      primary: brandPink,
      secondary: brandBlue,
      tertiary: Colors.white,
      surface: darkBg,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      error: const Color(0xFFE5484D),
      surfaceContainerHigh: darkSurface,
      surfaceContainerHighest: darkBorder,
      outline: darkBorder,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: Colors.white),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: const Color(0xFFE2E8F0)),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: darkTextMuted),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: darkTextMuted),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        hintStyle: const TextStyle(color: darkTextMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: brandPink, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5484D)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: brandPink,
        disabledColor: darkCard,
        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPink,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          iconSize: 22,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkBg,
        indicatorColor: darkCard,
        surfaceTintColor: darkBg,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : darkTextMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.white : darkTextMuted,
          );
        }),
      ),
    );
  }
}
