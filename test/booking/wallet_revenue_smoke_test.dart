import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/availability/data/repositories/tutor_availability_repository.dart';
import 'package:educonnect/features/booking/data/repositories/booking_repository.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('wallet receives revenue after confirmed session', () async {
    final url = Platform.environment['SUPABASE_URL'];
    final anonKey = Platform.environment['SUPABASE_ANON_KEY'];
    expect(url, isNotNull, reason: 'SUPABASE_URL wajib diisi');
    expect(anonKey, isNotNull, reason: 'SUPABASE_ANON_KEY wajib diisi');

    final stamp = DateTime.now().millisecondsSinceEpoch;
    const password = 'EduconnectTest!123';

    final studentClient = _createClient(url!, anonKey!);
    final tutorClient = _createClient(url, anonKey);

    final student = await _registerUser(
      client: studentClient,
      email: 'wallet.student.$stamp@educonnect.test',
      password: password,
      displayName: 'Wallet Student $stamp',
      role: AppUserRole.student,
    );
    final tutor = await _registerUser(
      client: tutorClient,
      email: 'wallet.tutor.$stamp@educonnect.test',
      password: password,
      displayName: 'Wallet Tutor $stamp',
      role: AppUserRole.tutor,
    );

    await tutorClient
        .from('tutors')
        .update({'price_per_hour': 80000})
        .eq('uid', tutor.uid);

    final studentRepo = BookingRepository(client: studentClient);
    final tutorRepo = BookingRepository(client: tutorClient);
    final availabilityRepo = TutorAvailabilityRepository(client: tutorClient);

    await availabilityRepo.addAvailabilitySlot(
      tutorUid: tutor.uid,
      weekday: DateTime.monday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    );
    await availabilityRepo.addAvailabilitySlot(
      tutorUid: tutor.uid,
      weekday: DateTime.wednesday,
      startTime: '15:00:00',
      endTime: '16:00:00',
    );

    final packageStartDate = _nextWeekdayDate(DateTime.now(), DateTime.monday);

    await studentRepo.createBooking(
      studentUid: student.uid,
      tutorUid: tutor.uid,
      subject: 'IPAS',
      packageStartDate: packageStartDate,
      packageMonths: 1,
      weeklySlots: const [
        BookingWeeklySlot(weekday: DateTime.monday, startTime: '15:00:00', endTime: '16:00:00'),
        BookingWeeklySlot(weekday: DateTime.wednesday, startTime: '15:00:00', endTime: '16:00:00'),
      ],
      durationMinutes: 60,
      message: 'Wallet smoke test',
    );

    final bookingRows = await studentClient
        .from('bookings')
        .select('id')
        .eq('student_uid', student.uid)
        .eq('tutor_uid', tutor.uid)
        .order('created_at', ascending: false)
        .limit(1);
    final bookingId = ((bookingRows as List).first as Map<String, dynamic>)['id'] as String;

    await tutorRepo.updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.awaitingPayment,
      actorUid: tutor.uid,
    );

    await expectLater(
      () => studentRepo.processSecureWebhookPayment(
        bookingId: bookingId,
        studentUid: student.uid,
        paymentMethod: 'gopay',
        signatureKey: 'invalid',
      ),
      throwsA(isA<PostgrestException>()),
    );

    final validSignature = _signatureForBooking(bookingId);
    await studentRepo.processSecureWebhookPayment(
      bookingId: bookingId,
      studentUid: student.uid,
      paymentMethod: 'gopay',
      signatureKey: validSignature,
    );

    final sessionRows = await tutorClient
        .from('booking_sessions')
        .select('id')
        .eq('booking_id', bookingId)
        .order('session_start', ascending: true)
        .limit(1);
    final sessionId = ((sessionRows as List).first as Map<String, dynamic>)['id'] as String;

    await tutorRepo.markSessionDoneByTutor(sessionId);
    await studentRepo.confirmSessionByStudent(
      sessionId: sessionId,
      rating: 5,
      review: 'Tutor hadir dan sesi berjalan baik.',
    );

    final walletRows = await tutorClient
        .from('tutor_wallets')
        .select('available_balance,total_earned,pending_balance')
        .eq('tutor_uid', tutor.uid)
        .limit(1);
    final wallet = ((walletRows as List).first as Map<String, dynamic>);
    final availableBalance = (wallet['available_balance'] as num?)?.toDouble() ?? 0;
    final totalEarned = (wallet['total_earned'] as num?)?.toDouble() ?? 0;

    expect(availableBalance, greaterThan(0), reason: 'saldo tutor harus bertambah setelah sesi dikonfirmasi');
    expect(totalEarned, greaterThan(0), reason: 'total pendapatan tutor harus tercatat');

    final transactionRows = await tutorClient
        .from('wallet_transactions')
        .select('reference_type,reference_id,amount,type')
        .eq('tutor_uid', tutor.uid)
        .eq('reference_type', 'booking_session')
        .eq('reference_id', sessionId);
    expect(transactionRows, isNotEmpty, reason: 'transaksi wallet untuk sesi harus tercatat');
  });
}

SupabaseClient _createClient(String url, String anonKey) {
  return SupabaseClient(
    url,
    anonKey,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    ),
  );
}

Future<AppAuthUser> _registerUser({
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
    displayName: (currentUser.userMetadata?['display_name'] as String?) ?? displayName,
    photoUrl: '',
  );
  await userRepo.upsertFromAuthUser(appUser);
  await userRepo.setRole(uid: currentUser.id, role: role);
  return appUser;
}

String _signatureForBooking(String bookingId) {
  final bytes = utf8.encode('${bookingId}EDUCONNECT_SECRET_SERVER_KEY');
  return md5.convert(bytes).toString();
}

DateTime _nextWeekdayDate(DateTime base, int weekday) {
  final normalized = DateTime(base.year, base.month, base.day);
  final diff = (weekday - normalized.weekday + 7) % 7;
  final offsetDays = diff == 0 ? 7 : diff;
  return normalized.add(Duration(days: offsetDays));
}
