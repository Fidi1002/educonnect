import 'package:educonnect/core/services/analytics_service.dart';
import 'package:educonnect/core/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const AnalyticsService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
