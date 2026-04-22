import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/core/utils/resilient_stream.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/chat/domain/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(client: ref.watch(supabaseClientProvider));
});

class ChatRepository {
  ChatRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Stream<List<ChatMessage>> watchBookingMessages(String bookingId) {
    return resilientStream(
      () => _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('booking_id', bookingId)
          .order('created_at')
          .map((rows) => rows.map(ChatMessage.fromMap).toList()),
    );
  }

  Stream<int> watchUnreadCount(String uid) {
    return resilientStream(
      () => _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('receiver_uid', uid)
          .map(
            (rows) => rows
                .where((row) => row['read_at'] == null || row['read_at'] == '')
                .length,
          ),
    );
  }

  Stream<int> watchUnreadByBooking({
    required String bookingId,
    required String receiverUid,
  }) {
    return resilientStream(
      () => _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('booking_id', bookingId)
          .map(
            (rows) => rows
                .where((row) => row['receiver_uid'] == receiverUid)
                .where((row) => row['read_at'] == null || row['read_at'] == '')
                .length,
          ),
    );
  }

  Future<void> sendMessage({
    required BookingItem booking,
    required String senderUid,
    required String body,
  }) async {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return;
    }

    final receiverUid = senderUid == booking.studentUid
        ? booking.tutorUid
        : booking.studentUid;

    if (receiverUid.isEmpty || receiverUid == senderUid) {
      throw const PostgrestException(
        message: 'Penerima chat tidak valid untuk booking ini.',
      );
    }

    await _client.from('messages').insert({
      'booking_id': booking.id,
      'sender_uid': senderUid,
      'receiver_uid': receiverUid,
      'body': trimmedBody,
    });
  }

  Future<void> markBookingMessagesAsRead({
    required String bookingId,
    required String receiverUid,
  }) async {
    await _client
        .from('messages')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('booking_id', bookingId)
        .eq('receiver_uid', receiverUid)
        .isFilter('read_at', null);
  }
}
