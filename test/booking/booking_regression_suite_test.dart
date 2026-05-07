import 'dart:io';

import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/availability/data/repositories/tutor_availability_repository.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/data/repositories/booking_repository.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Booking regression suite', () {
    group('State rules', () {
      test('scheduled flow states are not terminal', () {
        expect(BookingSessionStatus.scheduled.isTerminal, isFalse);
        expect(
          BookingSessionStatus.donePendingConfirmation.isTerminal,
          isFalse,
        );
        expect(BookingSessionStatus.disputedPending.isTerminal, isFalse);
      });

      test('final session states are terminal', () {
        expect(BookingSessionStatus.confirmed.isTerminal, isTrue);
        expect(BookingSessionStatus.disputedResolved.isTerminal, isTrue);
        expect(BookingSessionStatus.cancelledEarly.isTerminal, isTrue);
        expect(BookingSessionStatus.cancelledLate.isTerminal, isTrue);
        expect(BookingSessionStatus.rescheduled.isTerminal, isTrue);
        expect(BookingSessionStatus.studentNoShow.isTerminal, isTrue);
        expect(BookingSessionStatus.tutorNoShow.isTerminal, isTrue);
      });

      test('paid booking is no longer completed manually from UI flow', () {
        expect(
          canTransitionBookingStatus(
            from: BookingStatus.paid,
            to: BookingStatus.completed,
          ),
          isFalse,
        );
      });

      test('pending booking can still be accepted by tutor', () {
        expect(
          canTransitionBookingStatus(
            from: BookingStatus.pending,
            to: BookingStatus.awaitingPayment,
          ),
          isTrue,
        );
      });
    });

    group('Remote booking flow', () {
      test('pending -> awaiting_payment -> paid -> sessions visible', () async {
        final url = Platform.environment['SUPABASE_URL'];
        final anonKey = Platform.environment['SUPABASE_ANON_KEY'];
        expect(url, isNotNull, reason: 'SUPABASE_URL wajib diisi');
        expect(anonKey, isNotNull, reason: 'SUPABASE_ANON_KEY wajib diisi');

        final stamp = DateTime.now().millisecondsSinceEpoch;
        const password = 'EduconnectTest!123';
        final studentEmail = 'student.flow.$stamp@educonnect.test';
        final tutorEmail = 'tutor.flow.$stamp@educonnect.test';

        final studentClient = _createTestClient(url!, anonKey!);
        final tutorClient = _createTestClient(url, anonKey);

        final studentUser = await _registerAndPrepareUser(
          client: studentClient,
          email: studentEmail,
          password: password,
          displayName: 'Student Flow $stamp',
          role: AppUserRole.student,
        );
        final tutorUser = await _registerAndPrepareUser(
          client: tutorClient,
          email: tutorEmail,
          password: password,
          displayName: 'Tutor Flow $stamp',
          role: AppUserRole.tutor,
        );

        final studentBookingRepo = BookingRepository(client: studentClient);
        final tutorBookingRepo = BookingRepository(client: tutorClient);
        final tutorAvailabilityRepo = TutorAvailabilityRepository(
          client: tutorClient,
        );

        await _seedAvailability(tutorAvailabilityRepo, tutorUser.uid);

        final packageStartDate = _nextWeekdayDate(
          DateTime.now(),
          DateTime.monday,
        );
        const durationMinutes = 60;

        final paidBookingId = await _createBookingAndExpectPending(
          client: studentClient,
          bookingRepo: studentBookingRepo,
          studentUid: studentUser.uid,
          tutorUid: tutorUser.uid,
          subject: 'IPAS',
          packageStartDate: packageStartDate,
          durationMinutes: durationMinutes,
          weeklySlots: const [
            BookingWeeklySlot(
              weekday: DateTime.monday,
              startTime: '15:00:00',
              endTime: '16:00:00',
            ),
            BookingWeeklySlot(
              weekday: DateTime.wednesday,
              startTime: '15:00:00',
              endTime: '16:00:00',
            ),
          ],
        );

        await tutorBookingRepo.updateBookingStatus(
          bookingId: paidBookingId,
          status: BookingStatus.awaitingPayment,
          actorUid: tutorUser.uid,
        );
        await _expectBookingStatus(
          repo: tutorBookingRepo,
          bookingId: paidBookingId,
          expected: BookingStatus.awaitingPayment,
        );
        await _expectSessionCount(
          client: studentClient,
          bookingId: paidBookingId,
          expected: 0,
        );

        await studentBookingRepo.completeDummyPayment(
          bookingId: paidBookingId,
          studentUid: studentUser.uid,
        );
        await _expectBookingStatus(
          repo: studentBookingRepo,
          bookingId: paidBookingId,
          expected: BookingStatus.paid,
        );
        final paidSessionCount = await _sessionCount(
          client: studentClient,
          bookingId: paidBookingId,
        );
        expect(
          paidSessionCount,
          greaterThan(0),
          reason: 'booking paid harus menghasilkan sesi',
        );

        final pendingExpiryBookingId = await _createBookingAndExpectPending(
          client: studentClient,
          bookingRepo: studentBookingRepo,
          studentUid: studentUser.uid,
          tutorUid: tutorUser.uid,
          subject: 'Matematika',
          packageStartDate: packageStartDate,
          durationMinutes: durationMinutes,
          weeklySlots: const [
            BookingWeeklySlot(
              weekday: DateTime.tuesday,
              startTime: '15:00:00',
              endTime: '16:00:00',
            ),
            BookingWeeklySlot(
              weekday: DateTime.thursday,
              startTime: '15:00:00',
              endTime: '16:00:00',
            ),
          ],
        );
        await _forceBookingExpiry(
          client: studentClient,
          bookingId: pendingExpiryBookingId,
        );
        await _expectBookingStatus(
          repo: studentBookingRepo,
          bookingId: pendingExpiryBookingId,
          expected: BookingStatus.cancelled,
        );
        await _expectSessionCount(
          client: studentClient,
          bookingId: pendingExpiryBookingId,
          expected: 0,
        );

        final awaitingExpiryBookingId = await _createBookingAndExpectPending(
          client: studentClient,
          bookingRepo: studentBookingRepo,
          studentUid: studentUser.uid,
          tutorUid: tutorUser.uid,
          subject: 'Bahasa',
          packageStartDate: packageStartDate,
          durationMinutes: durationMinutes,
          weeklySlots: const [
            BookingWeeklySlot(
              weekday: DateTime.friday,
              startTime: '15:00:00',
              endTime: '16:00:00',
            ),
            BookingWeeklySlot(
              weekday: DateTime.saturday,
              startTime: '15:00:00',
              endTime: '16:00:00',
            ),
          ],
        );
        await tutorBookingRepo.updateBookingStatus(
          bookingId: awaitingExpiryBookingId,
          status: BookingStatus.awaitingPayment,
          actorUid: tutorUser.uid,
        );
        await _forceBookingExpiry(
          client: studentClient,
          bookingId: awaitingExpiryBookingId,
        );
        await _expectBookingStatus(
          repo: studentBookingRepo,
          bookingId: awaitingExpiryBookingId,
          expected: BookingStatus.cancelled,
        );
        await _expectPendingTransactionsResolved(
          client: studentClient,
          bookingId: awaitingExpiryBookingId,
        );
        await _expectSessionCount(
          client: studentClient,
          bookingId: awaitingExpiryBookingId,
          expected: 0,
        );

        final studentSessionRows = await studentClient
            .from('booking_sessions')
            .select('booking_id');
        final studentSessionBookingIds = (studentSessionRows as List<dynamic>)
            .map(
              (row) =>
                  (row as Map<String, dynamic>)['booking_id'] as String? ?? '',
            )
            .where((id) => id.isNotEmpty)
            .toSet();

        expect(
          studentSessionBookingIds,
          {paidBookingId},
          reason:
              'source sesi murid hanya boleh memuat booking aktif yang sudah paid',
        );
      });
    });
  });
}

SupabaseClient _createTestClient(String url, String anonKey) {
  return SupabaseClient(
    url,
    anonKey,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    ),
  );
}

Future<AppAuthUser> _registerAndPrepareUser({
  required SupabaseClient client,
  required String email,
  required String password,
  required String displayName,
  required AppUserRole role,
}) async {
  await client.auth.signUp(
    email: email,
    password: password,
    data: {'display_name': displayName},
  );
  if (client.auth.currentSession == null) {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  final currentUser = client.auth.currentUser;
  if (currentUser == null) {
    throw StateError('Autentikasi gagal untuk $email');
  }

  final userRepo = UserRepository(client: client);
  final appUser = AppAuthUser(
    uid: currentUser.id,
    email: currentUser.email ?? email,
    displayName:
        (currentUser.userMetadata?['display_name'] as String?) ?? displayName,
    photoUrl: '',
  );
  await userRepo.upsertFromAuthUser(appUser);
  await userRepo.setRole(uid: currentUser.id, role: role);
  return appUser;
}

Future<void> _seedAvailability(
  TutorAvailabilityRepository repo,
  String tutorUid,
) async {
  const slots = <BookingWeeklySlot>[
    BookingWeeklySlot(
      weekday: DateTime.monday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    ),
    BookingWeeklySlot(
      weekday: DateTime.tuesday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    ),
    BookingWeeklySlot(
      weekday: DateTime.wednesday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    ),
    BookingWeeklySlot(
      weekday: DateTime.thursday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    ),
    BookingWeeklySlot(
      weekday: DateTime.friday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    ),
    BookingWeeklySlot(
      weekday: DateTime.saturday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    ),
  ];

  for (final slot in slots) {
    await repo.addAvailabilitySlot(
      tutorUid: tutorUid,
      weekday: slot.weekday,
      startTime: slot.startTime,
      endTime: slot.endTime,
    );
  }
}

Future<String> _createBookingAndExpectPending({
  required SupabaseClient client,
  required BookingRepository bookingRepo,
  required String studentUid,
  required String tutorUid,
  required String subject,
  required DateTime packageStartDate,
  required int durationMinutes,
  required List<BookingWeeklySlot> weeklySlots,
}) async {
  await bookingRepo.createBooking(
    studentUid: studentUid,
    tutorUid: tutorUid,
    subject: subject,
    packageStartDate: packageStartDate,
    packageMonths: 1,
    weeklySlots: weeklySlots,
    durationMinutes: durationMinutes,
    message: 'Regression booking $subject',
  );

  final rows = await client
      .from('bookings')
      .select('id')
      .eq('tutor_uid', tutorUid)
      .eq('subject', subject)
      .order('created_at', ascending: false)
      .limit(1);
  final bookingId =
      ((rows as List<dynamic>).first as Map<String, dynamic>)['id'] as String;

  await _expectBookingStatus(
    repo: bookingRepo,
    bookingId: bookingId,
    expected: BookingStatus.pending,
  );
  await _expectSessionCount(client: client, bookingId: bookingId, expected: 0);
  return bookingId;
}

Future<void> _expectBookingStatus({
  required BookingRepository repo,
  required String bookingId,
  required BookingStatus expected,
}) async {
  final booking = await repo.fetchBookingById(bookingId);
  expect(booking, isNotNull);
  expect(booking!.status, expected);
}

Future<int> _sessionCount({
  required SupabaseClient client,
  required String bookingId,
}) async {
  final rows = await client
      .from('booking_sessions')
      .select('id')
      .eq('booking_id', bookingId);
  return (rows as List<dynamic>).length;
}

Future<void> _expectSessionCount({
  required SupabaseClient client,
  required String bookingId,
  required int expected,
}) async {
  expect(await _sessionCount(client: client, bookingId: bookingId), expected);
}

Future<void> _forceBookingExpiry({
  required SupabaseClient client,
  required String bookingId,
}) async {
  await client.from('bookings').update({
    'expires_at':
        DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
  }).eq('id', bookingId);
  await client.rpc(
    'expire_stale_bookings',
    params: {'p_booking_id': bookingId},
  );
}

Future<void> _expectPendingTransactionsResolved({
  required SupabaseClient client,
  required String bookingId,
}) async {
  final rows = await client
      .from('transactions')
      .select('payment_status')
      .eq('booking_id', bookingId);
  final statuses = (rows as List<dynamic>)
      .map(
        (row) =>
            (row as Map<String, dynamic>)['payment_status'] as String? ?? '',
      )
      .toList(growable: false);
  expect(statuses, isNotEmpty);
  expect(statuses.every((status) => status != 'pending'), isTrue);
}

DateTime _nextWeekdayDate(DateTime base, int weekday) {
  final normalized = DateTime(base.year, base.month, base.day);
  final diff = (weekday - normalized.weekday + 7) % 7;
  final offsetDays = diff == 0 ? 7 : diff;
  return normalized.add(Duration(days: offsetDays));
}
