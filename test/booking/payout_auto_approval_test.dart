import 'dart:io';

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
  test('payout auto-approval logic trigger tests', () async {
    final url = Platform.environment['SUPABASE_URL'];
    final anonKey = Platform.environment['SUPABASE_ANON_KEY'];
    expect(url, isNotNull, reason: 'SUPABASE_URL wajib diisi');
    expect(anonKey, isNotNull, reason: 'SUPABASE_ANON_KEY wajib diisi');

    final stamp = DateTime.now().millisecondsSinceEpoch;
    const password = 'EduconnectTest!123';

    final studentClient = _createClient(url!, anonKey!);
    final tutorClient = _createClient(url, anonKey);

    // Register Student and Tutor
    final student = await _registerUser(
      client: studentClient,
      email: 'payout.student.$stamp@educonnect.com',
      password: password,
      displayName: 'Payout Student $stamp',
      role: AppUserRole.student,
    );
    final tutor = await _registerUser(
      client: tutorClient,
      email: 'payout.tutor.$stamp@educonnect.com',
      password: password,
      displayName: 'Payout Tutor $stamp',
      role: AppUserRole.tutor,
    );

    // Set high tutor price per hour so we get Rp 5,000,000 from one session
    await tutorClient
        .from('tutors')
        .update({'price_per_hour': 5000000})
        .eq('uid', tutor.uid);

    final studentRepo = SupabaseBookingRepository(client: studentClient);
    final tutorRepo = SupabaseBookingRepository(client: tutorClient);
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
      subject: 'Fisika Payout',
      packageStartDate: packageStartDate,
      packageMonths: 1,
      weeklySlots: const [
        BookingWeeklySlot(weekday: DateTime.monday, startTime: '15:00:00', endTime: '16:00:00'),
        BookingWeeklySlot(weekday: DateTime.wednesday, startTime: '15:00:00', endTime: '16:00:00'),
      ],
      durationMinutes: 60,
      message: 'Payout simulation booking',
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

    await studentRepo.processSecureWebhookPayment(
      bookingId: bookingId,
      studentUid: student.uid,
      paymentMethod: 'gopay',
    );

    final sessionRows = await tutorClient
        .from('booking_sessions')
        .select('id')
        .eq('booking_id', bookingId)
        .order('session_start', ascending: true)
        .limit(1);
    final sessionId = ((sessionRows as List).first as Map<String, dynamic>)['id'] as String;

    // Complete session and confirm to transfer Rp 5.000.000 to tutor's wallet
    await tutorRepo.markSessionDoneByTutor(sessionId);
    await studentRepo.confirmSessionByStudent(
      sessionId: sessionId,
      rating: 5,
      review: 'Sesi selesai, pembayaran penuh.',
    );

    // Initial check: wallet exists and available balance is 5,000,000
    final initialWalletRows = await tutorClient
        .from('tutor_wallets')
        .select('available_balance,pending_balance')
        .eq('tutor_uid', tutor.uid)
        .limit(1);
    expect(initialWalletRows, isNotEmpty);
    final initialWallet = initialWalletRows.first;
    expect((initialWallet['available_balance'] as num).toDouble(), 5000000);
    expect(initialWallet['pending_balance'], 0);

    // 1. Test: Unapproved tutor cannot get auto-approved even if amount < 2,000,000
    // Set tutor to pending first to make sure they are not approved
    await tutorClient
        .from('tutors')
        .update({'verification_status': 'pending'})
        .eq('uid', tutor.uid);

    final tutorAfterPending = await tutorClient
        .from('tutors')
        .select('verification_status')
        .eq('uid', tutor.uid)
        .single();
    expect(tutorAfterPending['verification_status'], 'pending');

    // Request payout of 1,000,000
    final payoutId1 = await tutorClient.rpc('request_tutor_payout', params: {
      'p_tutor_uid': tutor.uid,
      'p_amount': 1000000,
      'p_bank_name': 'BCA',
      'p_account_number': '1234567890',
      'p_account_holder': 'Payout Tutor',
    }) as String;

    // Retrieve the payout request and verify it is pending
    final payout1Rows = await tutorClient
        .from('payout_requests')
        .select('status')
        .eq('id', payoutId1)
        .limit(1);
    expect(payout1Rows, isNotEmpty);
    expect(payout1Rows.first['status'], 'pending');

    // Available balance should be 4,000,000 and pending balance 1,000,000
    final wallet1Rows = await tutorClient
        .from('tutor_wallets')
        .select('available_balance,pending_balance')
        .eq('tutor_uid', tutor.uid)
        .limit(1);
    final wallet1 = wallet1Rows.first;
    expect((wallet1['available_balance'] as num).toDouble(), 4000000);
    expect((wallet1['pending_balance'] as num).toDouble(), 1000000);

    // 2. Test: Approved tutor with amount >= 2,000,000 does NOT get auto-approved
    // Set tutor to approved
    await tutorClient
        .from('tutors')
        .update({'verification_status': 'approved'})
        .eq('uid', tutor.uid);

    final tutorAfterApproved = await tutorClient
        .from('tutors')
        .select('verification_status')
        .eq('uid', tutor.uid)
        .single();
    expect(tutorAfterApproved['verification_status'], 'approved');

    // Request payout of 2,500,000
    final payoutId2 = await tutorClient.rpc('request_tutor_payout', params: {
      'p_tutor_uid': tutor.uid,
      'p_amount': 2500000,
      'p_bank_name': 'BCA',
      'p_account_number': '1234567890',
      'p_account_holder': 'Payout Tutor',
    }) as String;

    // Retrieve the payout request and verify it is pending
    final payout2Rows = await tutorClient
        .from('payout_requests')
        .select('status')
        .eq('id', payoutId2)
        .limit(1);
    expect(payout2Rows, isNotEmpty);
    expect(payout2Rows.first['status'], 'pending');

    // Available balance should be 1,500,000 and pending balance 3,500,000 (1m + 2.5m)
    final wallet2Rows = await tutorClient
        .from('tutor_wallets')
        .select('available_balance,pending_balance')
        .eq('tutor_uid', tutor.uid)
        .limit(1);
    final wallet2 = wallet2Rows.first;
    expect((wallet2['available_balance'] as num).toDouble(), 1500000);
    expect((wallet2['pending_balance'] as num).toDouble(), 3500000);

    // 3. Test: Approved tutor with amount < 2,000,000 gets auto-approved instantly
    // Request payout of 1,200,000
    final payoutId3 = await tutorClient.rpc('request_tutor_payout', params: {
      'p_tutor_uid': tutor.uid,
      'p_amount': 1200000,
      'p_bank_name': 'BCA',
      'p_account_number': '1234567890',
      'p_account_holder': 'Payout Tutor',
    }) as String;

    // Retrieve the payout request and verify it is completed (auto-approved)
    final payout3Rows = await tutorClient
        .from('payout_requests')
        .select('status')
        .eq('id', payoutId3)
        .limit(1);
    expect(payout3Rows, isNotEmpty);
    expect(payout3Rows.first['status'], 'completed');

    // Available balance should be 300,000 (1,500,000 - 1,200,000)
    // Pending balance should remain 3,500,000 because:
    // - request_tutor_payout inserts with pending -> available = 300,000, pending = 4,700,000
    // - trigger automatically updates status to completed -> pending = 4,700,000 - 1,200,000 = 3,500,000
    final wallet3Rows = await tutorClient
        .from('tutor_wallets')
        .select('available_balance,pending_balance')
        .eq('tutor_uid', tutor.uid)
        .limit(1);
    final wallet3 = wallet3Rows.first;
    expect((wallet3['available_balance'] as num).toDouble(), 300000);
    expect((wallet3['pending_balance'] as num).toDouble(), 3500000);

    // Check transaction records: should have a wallet_transaction for payout confirmation
    final txRows = await tutorClient
        .from('wallet_transactions')
        .select('description,type')
        .eq('tutor_uid', tutor.uid)
        .eq('reference_id', payoutId3);
    
    // There should be a debit transaction confirming the transfer
    final completedTx = txRows.firstWhere((tx) => (tx as Map)['description'].toString().contains('Pencairan dana selesai ditransfer'));
    expect(completedTx, isNotNull);
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
  final userRepo = SupabaseUserRepository(client: client);
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

DateTime _nextWeekdayDate(DateTime base, int weekday) {
  final normalized = DateTime(base.year, base.month, base.day);
  final diff = (weekday - normalized.weekday + 7) % 7;
  final offsetDays = diff == 0 ? 7 : diff;
  return normalized.add(Duration(days: offsetDays));
}
