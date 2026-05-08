import 'package:educonnect/app/app.dart';
import 'package:educonnect/core/services/backend_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:educonnect/core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.initialize();
  final bootstrapResult = await BackendBootstrap.initialize();
  runApp(ProviderScope(child: EduConnectApp(bootstrapResult: bootstrapResult)));
}
