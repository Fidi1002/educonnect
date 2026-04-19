import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/data/repositories/booking_repository.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookingLoadingProvider = StateProvider<bool>((ref) => false);

final myStudentBookingsProvider = StreamProvider<List<BookingItem>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<List<BookingItem>>.empty();
  }
  return ref.watch(bookingRepositoryProvider).watchStudentBookings(user.uid);
});

final myTutorBookingsProvider = StreamProvider<List<BookingItem>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<List<BookingItem>>.empty();
  }
  return ref.watch(bookingRepositoryProvider).watchTutorBookings(user.uid);
});

final tutorPendingBookingsProvider = StreamProvider<List<BookingItem>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<List<BookingItem>>.empty();
  }
  return ref
      .watch(bookingRepositoryProvider)
      .watchTutorBookings(user.uid, pendingOnly: true);
});

final studentAwaitingPaymentCountProvider = Provider<int>((ref) {
  final items = ref.watch(myStudentBookingsProvider).valueOrNull ?? const [];
  return items
      .where((item) => item.status == BookingStatus.awaitingPayment)
      .length;
});

final studentPaidCountProvider = Provider<int>((ref) {
  final items = ref.watch(myStudentBookingsProvider).valueOrNull ?? const [];
  return items.where((item) => item.status == BookingStatus.paid).length;
});

final tutorAwaitingPaymentCountProvider = Provider<int>((ref) {
  final items = ref.watch(myTutorBookingsProvider).valueOrNull ?? const [];
  return items
      .where((item) => item.status == BookingStatus.awaitingPayment)
      .length;
});

final bookingControllerProvider = Provider<BookingController>((ref) {
  return BookingController(ref);
});

class BookingController {
  BookingController(this._ref);

  final Ref _ref;

  BookingRepository get _repository => _ref.read(bookingRepositoryProvider);

  String _requireUid() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('User belum login.');
    }
    return user.uid;
  }

  Future<void> createBooking({
    required String tutorUid,
    required String subject,
    required DateTime sessionStart,
    required int durationMinutes,
    required String message,
  }) async {
    final studentUid = _requireUid();
    await _runLoadingTask(
      () => _repository.createBooking(
        studentUid: studentUid,
        tutorUid: tutorUid,
        subject: subject,
        sessionStart: sessionStart,
        durationMinutes: durationMinutes,
        message: message,
      ),
    );
  }

  Future<void> respondBooking({
    required String bookingId,
    required BookingStatus status,
  }) {
    return _runLoadingTask(
      () =>
          _repository.updateBookingStatus(bookingId: bookingId, status: status),
    );
  }

  Future<void> payDummyBooking({required String bookingId}) async {
    final studentUid = _requireUid();
    await _runLoadingTask(
      () => _repository.completeDummyPayment(
        bookingId: bookingId,
        studentUid: studentUid,
      ),
    );
  }

  Future<T> _runLoadingTask<T>(Future<T> Function() action) async {
    _ref.read(bookingLoadingProvider.notifier).state = true;
    try {
      return await action();
    } finally {
      _ref.read(bookingLoadingProvider.notifier).state = false;
    }
  }
}
