import 'dart:async';

import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/core/utils/resilient_stream.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/chat/domain/models/chat_message.dart';
import 'package:educonnect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return SupabaseChatRepository(client: ref.watch(supabaseClientProvider));
});

class SupabaseChatRepository implements IChatRepository {
  SupabaseChatRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
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

  @override
  Stream<int> watchUnreadCount(String uid) {
    final controller = StreamController<int>();

    Future<void> fetchCount() async {
      try {
        final res = await _client
            .from('messages')
            .select('id')
            .eq('receiver_uid', uid)
            .isFilter('read_at', null);
        if (!controller.isClosed) {
          controller.add(res.length);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    fetchCount();

    final channel = _client
        .channel('unread_count_all_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_uid',
            value: uid,
          ),
          callback: (payload) {
            fetchCount();
          },
        );

    channel.subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Stream<int> watchUnreadByBooking({
    required String bookingId,
    required String receiverUid,
  }) {
    final controller = StreamController<int>();

    Future<void> fetchCount() async {
      try {
        final res = await _client
            .from('messages')
            .select('id')
            .eq('booking_id', bookingId)
            .eq('receiver_uid', receiverUid)
            .isFilter('read_at', null);
        if (!controller.isClosed) {
          controller.add(res.length);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    fetchCount();

    final channel = _client
        .channel('unread_count_booking_${bookingId}_$receiverUid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booking_id',
            value: bookingId,
          ),
          callback: (payload) {
            fetchCount();
          },
        );

    channel.subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
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

  @override
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
