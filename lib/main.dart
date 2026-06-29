import 'package:educonnect/app/app.dart';
import 'package:educonnect/core/services/backend_bootstrap.dart';
import 'package:educonnect/core/presentation/providers/shared_preferences_provider.dart';
import 'package:educonnect/core/services/local_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:educonnect/core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  await LocalNotificationService.initialize();
  await LocalCacheService.initialize();
  final bootstrapResult = await BackendBootstrap.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: EduConnectApp(bootstrapResult: bootstrapResult),
    ),
  );
}

