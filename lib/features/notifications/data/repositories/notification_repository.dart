import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/core/utils/resilient_stream.dart';
import 'package:educonnect/features/notifications/domain/models/app_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(client: ref.watch(supabaseClientProvider));
});

class NotificationRepository {
  NotificationRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Stream<List<AppNotification>> watchMyNotifications(String userUid) {
    return resilientStream(
      () => _client
          .from('app_notifications')
          .stream(primaryKey: ['id'])
          .eq('user_uid', userUid)
          .order('created_at', ascending: false)
          .map((rows) => rows.map(AppNotification.fromMap).toList()),
    );
  }

  Future<void> markAsRead(String id) {
    return _client
        .from('app_notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead(String userUid) {
    return _client
        .from('app_notifications')
        .update({'is_read': true})
        .eq('user_uid', userUid)
        .eq('is_read', false);
  }

  Future<String?> resolveBookingIdFromTarget({
    required String targetType,
    required String targetId,
  }) async {
    if (targetId.trim().isEmpty) {
      return null;
    }

    if (targetType == 'booking') {
      return targetId;
    }

    if (targetType == 'session_change' || targetType == 'booking_session') {
      final row = await _client
          .from('booking_sessions')
          .select('booking_id')
          .eq('id', targetId)
          .maybeSingle();
      return row?['booking_id'] as String?;
    }

    return null;
  }
}
