import 'package:educonnect/app/routes/app_router.dart';
import 'package:educonnect/core/services/backend_bootstrap.dart';
import 'package:educonnect/features/setup/presentation/pages/setup_required_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EduConnectApp extends ConsumerWidget {
  const EduConnectApp({required this.bootstrapResult, super.key});

  final BootstrapResult bootstrapResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primary = Color(0xFF4B176E);
    const accent = Color(0xFF8C4BC0);
    const surface = Color(0xFFF5F5F7);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: const Color(0xFFE5484D),
          surfaceContainerHigh: const Color(0xFFEDECF2),
          surfaceContainerHighest: const Color(0xFFE8E7EF),
          outline: const Color(0xFFD1CEDA),
        );

    final theme = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF9A98A3)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD1CEDA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFEAF8),
        selectedColor: primary,
        disabledColor: const Color(0xFFEBE8F0),
        labelStyle: const TextStyle(color: Color(0xFF2D2A35)),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8DBF4),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            color: selected ? primary : const Color(0xFF7A7686),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : const Color(0xFF7A7686),
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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EduConnect',
      theme: theme,
      routerConfig: router,
    );
  }
}
