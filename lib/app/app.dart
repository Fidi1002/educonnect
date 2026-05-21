import 'package:google_fonts/google_fonts.dart';
import 'package:educonnect/app/routes/app_router.dart';
import 'package:educonnect/core/presentation/app_messenger.dart';
import 'package:educonnect/core/presentation/widgets/push_notification_bootstrapper.dart';
import 'package:educonnect/core/services/backend_bootstrap.dart';
import 'package:educonnect/features/setup/presentation/pages/setup_required_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EduConnectApp extends ConsumerWidget {
  const EduConnectApp({required this.bootstrapResult, super.key});

  final BootstrapResult bootstrapResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const brandPink = Color(0xFFFF1377);
    const brandNavy = Color(0xFF4B176E);
    const brandBlue = Color(0xFF6366F1); // Premium Indigo
    const surface = Color(0xFFF7F9FF);
    const surfaceSoft = Color(0xFFEAF2FF);
    const textMuted = Color(0xFF667085);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: brandNavy, // Seed from main brand color
          brightness: Brightness.light,
        ).copyWith(
          primary: brandNavy,
          secondary: brandBlue,
          tertiary: brandPink,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: brandNavy,
          error: const Color(0xFFE5484D),
          surfaceContainerHigh: surfaceSoft,
          surfaceContainerHighest: const Color(0xFFDCE8FF),
          outline: const Color(0xFFC9D8F2),
        );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    final theme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
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
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textMuted),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: brandNavy, fontWeight: FontWeight.w700),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: textMuted),
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
        backgroundColor: surfaceSoft,
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
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brandNavy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandPink,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandBlue,
        linearTrackColor: Color(0xFFDCE8FF),
        circularTrackColor: Color(0xFFDCE8FF),
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
            color: selected ? brandNavy : textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? brandNavy : textMuted,
          );
        }),
      ),
    );

    if (!bootstrapResult.isSuccess) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EduConnect',
        theme: theme,
        home: SetupRequiredPage(
          errorMessage: bootstrapResult.errorMessage ?? 'Unknown error',
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return PushNotificationBootstrapper(
      child: MaterialApp.router(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'EduConnect',
        theme: theme,
        routerConfig: router,
      ),
    );
  }
}
