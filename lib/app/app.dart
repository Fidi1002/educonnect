import 'package:educonnect/app/routes/app_router.dart';

import 'package:educonnect/core/presentation/app_messenger.dart';
import 'package:educonnect/core/presentation/widgets/push_notification_bootstrapper.dart';
import 'package:educonnect/core/services/backend_bootstrap.dart';
import 'package:educonnect/core/presentation/theme/app_theme.dart';
import 'package:educonnect/core/presentation/providers/theme_provider.dart';
import 'package:educonnect/core/presentation/providers/locale_provider.dart';
import 'package:educonnect/features/setup/presentation/pages/setup_required_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EduConnectApp extends ConsumerWidget {
  const EduConnectApp({required this.bootstrapResult, super.key});

  final BootstrapResult bootstrapResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    if (!bootstrapResult.isSuccess) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EduConnect',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
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
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        routerConfig: router,
      ),
    );
  }
}

