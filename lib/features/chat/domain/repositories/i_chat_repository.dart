import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/chat/domain/models/chat_message.dart';

abstract class IChatRepository {
  Stream<List<ChatMessage>> watchBookingMessages(String bookingId);
  Stream<int> watchUnreadCount(String uid);
  
  Stream<int> watchUnreadByBooking({
    required String bookingId,
    required String receiverUid,
  });

  Future<void> sendMessage({
    required BookingItem booking,
    required String senderUid,
    required String body,
  });

  Future<void> markBookingMessagesAsRead({
    required String bookingId,
    required String receiverUid,
  });
}
