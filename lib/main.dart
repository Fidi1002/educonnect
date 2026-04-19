import 'package:educonnect/app/app.dart';
import 'package:educonnect/core/services/backend_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrapResult = await BackendBootstrap.initialize();
  runApp(ProviderScope(child: EduConnectApp(bootstrapResult: bootstrapResult)));
}
