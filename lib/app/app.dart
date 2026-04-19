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
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7E8C)),
      useMaterial3: true,
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
