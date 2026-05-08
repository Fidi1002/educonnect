import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(client: ref.watch(supabaseClientProvider));
});

class PushTokenRepository {
  PushTokenRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Future<void> upsertDeviceToken({
    required String userUid,
    required String token,
    required String platform,
    String deviceLabel = '',
  }) async {
    await _client.from('user_push_tokens').upsert({
      'user_uid': userUid,
      'push_provider': 'fcm',
      'platform': platform,
      'device_token': token,
      'device_label': deviceLabel,
      'is_active': true,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'device_token');
  }

  Future<void> deactivateDeviceToken(String token) async {
    await _client
        .from('user_push_tokens')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('device_token', token);
  }
}
