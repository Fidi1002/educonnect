import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/data/repositories/booking_repository.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/chat/data/repositories/chat_repository.dart';
import 'package:educonnect/features/chat/domain/models/chat_message.dart';
import 'package:educonnect/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatSendingProvider = StateProvider<bool>((ref) => false);

final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<int>.empty();
  }
  return ref.watch(chatRepositoryProvider).watchUnreadCount(user.uid);
});

final bookingMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, bookingId) {
      return ref.watch(chatRepositoryProvider).watchBookingMessages(bookingId);
    });

final unreadByBookingProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  bookingId,
) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<int>.empty();
  }
  return ref
      .watch(chatRepositoryProvider)
      .watchUnreadByBooking(bookingId: bookingId, receiverUid: user.uid);
});

final bookingByIdProvider = StreamProvider.autoDispose
    .family<BookingItem?, String>((ref, bookingId) {
      return ref.watch(bookingRepositoryProvider).watchBookingById(bookingId);
    });

final latestMessageByBookingProvider = Provider.autoDispose
    .family<ChatMessage?, String>((ref, bookingId) {
      final messages = ref
          .watch(bookingMessagesProvider(bookingId))
          .valueOrNull;
      if (messages == null || messages.isEmpty) {
        return null;
      }
      return messages.last;
    });

final inboxBookingsProvider = StreamProvider<List<BookingItem>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<List<BookingItem>>.empty();
  }

  final profile = ref.watch(currentUserProfileProvider).value;
  if (profile == null) {
    return const Stream<List<BookingItem>>.empty();
  }

  if (profile.role == AppUserRole.tutor) {
    return ref.watch(bookingRepositoryProvider).watchTutorBookings(user.uid);
  }
  return ref.watch(bookingRepositoryProvider).watchStudentBookings(user.uid);
});

final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(ref);
});

class ChatController {
  ChatController(this._ref);

  final Ref _ref;

  IChatRepository get _chatRepository => _ref.read(chatRepositoryProvider);

  String _requireUid() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('User belum login.');
    }
    return user.uid;
  }

  Future<void> sendMessage({
    required BookingItem booking,
    required String body,
  }) async {
    final senderUid = _requireUid();
    await _runSendingTask(
      () => _chatRepository.sendMessage(
        booking: booking,
        senderUid: senderUid,
        body: body,
      ),
    );
  }

  Future<void> markAsRead(String bookingId) {
    final uid = _requireUid();
    return _chatRepository.markBookingMessagesAsRead(
      bookingId: bookingId,
      receiverUid: uid,
    );
  }

  Future<T> _runSendingTask<T>(Future<T> Function() action) async {
    _ref.read(chatSendingProvider.notifier).state = true;
    try {
      return await action();
    } finally {
      _ref.read(chatSendingProvider.notifier).state = false;
    }
  }
}
