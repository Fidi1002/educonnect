import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/data/repositories/booking_repository.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:educonnect/features/booking/domain/models/session_change_request.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
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

final bookingSessionsProvider = StreamProvider.autoDispose
    .family<List<BookingSession>, String>((ref, bookingId) {
      return ref
          .watch(bookingRepositoryProvider)
          .watchBookingSessions(bookingId);
    });

final tutorBookedWeeklySlotsProvider = FutureProvider.autoDispose
    .family<List<BookingWeeklySlot>, String>((ref, tutorUid) {
  return ref.watch(bookingRepositoryProvider).fetchBookedWeeklySlots(tutorUid);
});

final myStudentSessionsStreamProvider = StreamProvider<List<BookingSession>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<List<BookingSession>>.empty();
  }
  return ref
      .watch(bookingRepositoryProvider)
      .watchStudentBookingSessions(user.uid);
});

final myTutorSessionsStreamProvider = StreamProvider<List<BookingSession>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<List<BookingSession>>.empty();
  }
  return ref
      .watch(bookingRepositoryProvider)
      .watchTutorBookingSessions(user.uid);
});

final myStudentSessionsProvider = Provider<AsyncValue<List<BookingSession>>>((
  ref,
) {
  final bookings = ref.watch(myStudentBookingsProvider);
  final sessions = ref.watch(myStudentSessionsStreamProvider);
  return sessions.whenData(
    (items) => _filterSessionsByVisibleBookings(
      items,
      bookings.valueOrNull ?? const [],
    ),
  );
});

final myTutorSessionsProvider = Provider<AsyncValue<List<BookingSession>>>((
  ref,
) {
  final bookings = ref.watch(myTutorBookingsProvider);
  final sessions = ref.watch(myTutorSessionsStreamProvider);
  return sessions.whenData(
    (items) => _filterSessionsByVisibleBookings(
      items,
      bookings.valueOrNull ?? const [],
    ),
  );
});

final myTutorPendingHomeworkProvider =
    StreamProvider<List<SessionLearningRecord>>((ref) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) {
        return const Stream<List<SessionLearningRecord>>.empty();
      }
      return ref
          .watch(bookingRepositoryProvider)
          .watchTutorPendingHomeworkRecords(user.uid);
    });

final myStudentLearningRecordsProvider =
    StreamProvider<List<SessionLearningRecord>>((ref) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) {
        return const Stream<List<SessionLearningRecord>>.empty();
      }
      return ref
          .watch(bookingRepositoryProvider)
          .watchStudentLearningRecords(user.uid);
    });

final sessionChangeRequestsProvider = StreamProvider.autoDispose
    .family<List<SessionChangeRequest>, String>((ref, bookingId) {
      return ref
          .watch(bookingRepositoryProvider)
          .watchBookingSessionChangeRequests(bookingId);
    });

final sessionLearningRecordsProvider = StreamProvider.autoDispose
    .family<List<SessionLearningRecord>, String>((ref, bookingId) {
      return ref
          .watch(bookingRepositoryProvider)
          .watchSessionLearningRecords(bookingId);
    });

final studentUpcomingBookingsProvider = Provider<List<BookingItem>>((ref) {
  final items = ref.watch(myStudentBookingsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  return items
      .where((item) => isStudentUpcomingBooking(item, now: now))
      .toList()
    ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
});

final studentHistoryBookingsProvider = Provider<List<BookingItem>>((ref) {
  final items = ref.watch(myStudentBookingsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  return items
      .where((item) => !isStudentUpcomingBooking(item, now: now))
      .toList()
    ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));
});

final tutorIncomingRequestsProvider = Provider<List<BookingItem>>((ref) {
  final items = ref.watch(myTutorBookingsProvider).valueOrNull ?? const [];
  return items.where((item) => item.status == BookingStatus.pending).toList()
    ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
});

final tutorActiveScheduleProvider = Provider<List<BookingItem>>((ref) {
  final items = ref.watch(myTutorBookingsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  return items.where((item) => isTutorActiveBooking(item, now: now)).toList()
    ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
});

final tutorHistoryBookingsProvider = Provider<List<BookingItem>>((ref) {
  final items = ref.watch(myTutorBookingsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  return items.where((item) => isTutorHistoryBooking(item, now: now)).toList()
    ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));
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
    required DateTime packageStartDate,
    required int packageMonths,
    required List<BookingWeeklySlot> weeklySlots,
    required int durationMinutes,
    required String message,
  }) async {
    final studentUid = _requireUid();
    await _runLoadingTask(
      () => _repository.createBooking(
        studentUid: studentUid,
        tutorUid: tutorUid,
        subject: subject,
        packageStartDate: packageStartDate,
        packageMonths: packageMonths,
        weeklySlots: weeklySlots,
        durationMinutes: durationMinutes,
        message: message,
      ),
    );
  }

  Future<void> respondBooking({
    required String bookingId,
    required BookingStatus status,
  }) async {
    final actorUid = _requireUid();
    final current = await _repository.fetchBookingById(bookingId);
    if (current == null) {
      throw StateError('Booking tidak ditemukan.');
    }

    if (!canTransitionBookingStatus(from: current.status, to: status)) {
      throw StateError(
        'Transisi status tidak valid: ${current.status.label} -> ${status.label}.',
      );
    }

    await _runLoadingTask(
      () => _repository.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        actorUid: actorUid,
      ),
    );
  }

  Future<void> paySecureWebhookBooking({
    required String bookingId,
    required String paymentMethod,
  }) async {
    final studentUid = _requireUid();
    final bytes = utf8.encode('${bookingId}EDUCONNECT_SECRET_SERVER_KEY');
    final signatureKey = md5.convert(bytes).toString();

    await _runLoadingTask(
      () => _repository.processSecureWebhookPayment(
        bookingId: bookingId,
        studentUid: studentUid,
        paymentMethod: paymentMethod,
        signatureKey: signatureKey,
      ),
    );
  }

  Future<void> processSmartSessionReminders() async {
    final studentUid = _requireUid();
    await _repository.processStudentSessionReminders(studentUid);
  }

  Future<void> processAutoConfirmations() async {
    await _repository.processAutoConfirmSessions();
  }

  Future<void> markSessionStartedByTutor(String sessionId) {
    return _runLoadingTask(() => _repository.markSessionStartedByTutor(sessionId));
  }

  Future<void> markSessionDoneByTutor(String sessionId) {
    return _runLoadingTask(() => _repository.markSessionDoneByTutor(sessionId));
  }

  Future<void> markStudentNoShow(String sessionId) {
    return _runLoadingTask(
      () => _repository.markStudentNoShowByTutor(sessionId),
    );
  }

  Future<void> markTutorNoShow(String sessionId) {
    return _runLoadingTask(
      () => _repository.markTutorNoShowByStudent(sessionId),
    );
  }

  Future<void> confirmSessionByStudent({
    required String sessionId,
    int? rating,
    String review = '',
  }) {
    return _runLoadingTask(
      () => _repository.confirmSessionByStudent(
        sessionId: sessionId,
        rating: rating,
        review: review,
      ),
    );
  }

  Future<void> disputeSessionByStudent(String sessionId) {
    return _runLoadingTask(
      () => _repository.disputeSessionByStudent(sessionId),
    );
  }

  Future<void> resolveDisputeByTutor(String sessionId) {
    return _runLoadingTask(() => _repository.resolveDisputeByTutor(sessionId));
  }

  Future<void> confirmSessionPresence(String sessionId) {
    return _runLoadingTask(
      () => _repository.confirmSessionPresenceByStudent(sessionId),
    );
  }

  Future<void> requestSessionCancel({
    required String sessionId,
    required String reason,
  }) async {
    final uid = _requireUid();
    await _runLoadingTask(
      () => _repository.requestSessionCancel(
        sessionId: sessionId,
        requesterUid: uid,
        reason: reason,
      ),
    );
  }

  Future<void> requestSessionReschedule({
    required String sessionId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required String reason,
  }) async {
    final uid = _requireUid();
    await _runLoadingTask(
      () => _repository.requestSessionReschedule(
        sessionId: sessionId,
        requesterUid: uid,
        proposedStart: proposedStart,
        proposedEnd: proposedEnd,
        reason: reason,
      ),
    );
  }

  Future<void> saveTutorLearningRecord({
    required String bookingId,
    required String sessionId,
    required String studentUid,
    required String materialSummary,
    required String materialNotes,
    required String homeworkTitle,
    required String homeworkDescription,
  }) async {
    final tutorUid = _requireUid();
    await _runLoadingTask(
      () => _repository.upsertTutorLearningRecord(
        bookingId: bookingId,
        sessionId: sessionId,
        tutorUid: tutorUid,
        studentUid: studentUid,
        materialSummary: materialSummary,
        materialNotes: materialNotes,
        homeworkTitle: homeworkTitle,
        homeworkDescription: homeworkDescription,
      ),
    );
  }

  Future<void> submitHomework({
    required String sessionId,
    required String submissionText,
  }) async {
    await _runLoadingTask(
      () => _repository.submitHomeworkByStudent(
        sessionId: sessionId,
        submissionText: submissionText,
      ),
    );
  }

  Future<void> markHomeworkReviewed({required String sessionId}) async {
    await _runLoadingTask(
      () => _repository.markHomeworkReviewedByTutor(sessionId: sessionId),
    );
  }

  Future<void> respondSessionChangeRequest({
    required String requestId,
    required bool approved,
  }) async {
    final uid = _requireUid();
    await _runLoadingTask(
      () => _repository.respondSessionChangeRequest(
        requestId: requestId,
        reviewerUid: uid,
        approved: approved,
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

List<BookingSession> _filterSessionsByVisibleBookings(
  List<BookingSession> sessions,
  List<BookingItem> bookings,
) {
  final visibleBookingIds = bookings
      .where(_shouldExposeBookingSessions)
      .map((booking) => booking.id)
      .toSet();
  return sessions
      .where((session) => visibleBookingIds.contains(session.bookingId))
      .toList(growable: false);
}

bool _shouldExposeBookingSessions(BookingItem booking) {
  switch (booking.status) {
    case BookingStatus.pending:
    case BookingStatus.rejected:
    case BookingStatus.cancelled:
      return false;
    case BookingStatus.awaitingPayment:
    case BookingStatus.paid:
    case BookingStatus.completed:
      return true;
  }
}

bool isStudentUpcomingBooking(BookingItem item, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final activeStatus =
      item.status == BookingStatus.pending ||
      item.status == BookingStatus.awaitingPayment ||
      item.status == BookingStatus.paid;
  return activeStatus && item.sessionEnd.isAfter(reference);
}

bool isTutorActiveBooking(BookingItem item, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final activeStatus =
      item.status == BookingStatus.awaitingPayment ||
      item.status == BookingStatus.paid;
  return activeStatus && item.sessionEnd.isAfter(reference);
}

bool isTutorHistoryBooking(BookingItem item, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  if (item.status == BookingStatus.pending) {
    return item.sessionEnd.isBefore(reference);
  }
  if (isTutorActiveBooking(item, now: reference)) {
    return false;
  }
  return true;
}

bool canTransitionBookingStatus({
  required BookingStatus from,
  required BookingStatus to,
}) {
  if (from == to) {
    return true;
  }

  switch (from) {
    case BookingStatus.pending:
      return to == BookingStatus.awaitingPayment ||
          to == BookingStatus.rejected ||
          to == BookingStatus.cancelled;
    case BookingStatus.awaitingPayment:
      return to == BookingStatus.paid || to == BookingStatus.cancelled;
    case BookingStatus.paid:
      return to == BookingStatus.cancelled;
    case BookingStatus.rejected:
    case BookingStatus.completed:
    case BookingStatus.cancelled:
      return false;
  }
}
