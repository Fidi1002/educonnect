import 'dart:io';

import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/availability/data/repositories/tutor_availability_repository.dart';
import 'package:educonnect/features/booking/data/repositories/booking_repository.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:educonnect/features/notifications/data/repositories/push_token_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('chat message insert triggers app_notification and push_delivery_queue entry', () async {
    final url = Platform.environment['SUPABASE_URL'];
    final anonKey = Platform.environment['SUPABASE_ANON_KEY'];
    expect(url, isNotNull, reason: 'SUPABASE_URL wajib diisi');
    expect(anonKey, isNotNull, reason: 'SUPABASE_ANON_KEY wajib diisi');

    final stamp = DateTime.now().millisecondsSinceEpoch;
    const password = 'EduconnectTest!123';

    final studentClient = _createClient(url!, anonKey!);
    final tutorClient = _createClient(url, anonKey);

    // 1. Register student & tutor
    final student = await _registerUser(
      client: studentClient,
      email: 'chat.student.$stamp@educonnect.com',
      password: password,
      displayName: 'Chat Student $stamp',
      role: AppUserRole.student,
    );
    final tutor = await _registerUser(
      client: tutorClient,
      email: 'chat.tutor.$stamp@educonnect.com',
      password: password,
      displayName: 'Chat Tutor $stamp',
      role: AppUserRole.tutor,
    );

    // Register push token for tutor so push notification enqueuing trigger can process it
    final pushTokenRepo = PushTokenRepository(client: tutorClient);
    await pushTokenRepo.upsertDeviceToken(
      userUid: tutor.uid,
      token: 'tutor_push_token_$stamp',
      platform: 'android',
      deviceLabel: 'Tutor Test Device',
    );

    // Set availability so booking validation passes
    final availabilityRepo = TutorAvailabilityRepository(client: tutorClient);
    await availabilityRepo.addAvailabilitySlot(
      tutorUid: tutor.uid,
      weekday: DateTime.monday,
      startTime: '16:00:00',
      endTime: '17:00:00',
    );
    await availabilityRepo.addAvailabilitySlot(
      tutorUid: tutor.uid,
      weekday: DateTime.wednesday,
      startTime: '16:00:00',
      endTime: '17:00:00',
    );

    final studentRepo = SupabaseBookingRepository(client: studentClient);
    final tutorRepo = SupabaseBookingRepository(client: tutorClient);

    // 2. Create Booking
    final packageStartDate = _nextWeekdayDate(DateTime.now(), DateTime.monday);
    await studentRepo.createBooking(
      studentUid: student.uid,
      tutorUid: tutor.uid,
      subject: 'Matematika',
      packageStartDate: packageStartDate,
      packageMonths: 1,
      weeklySlots: const [
        BookingWeeklySlot(weekday: DateTime.monday, startTime: '16:00:00', endTime: '17:00:00'),
        BookingWeeklySlot(weekday: DateTime.wednesday, startTime: '16:00:00', endTime: '17:00:00'),
      ],
      durationMinutes: 60,
      message: 'Chat integration test booking',
    );

    final bookingRows = await studentClient
        .from('bookings')
        .select('id')
        .eq('student_uid', student.uid)
        .eq('tutor_uid', tutor.uid)
        .order('created_at', ascending: false)
        .limit(1);
    final bookingId = ((bookingRows as List).first as Map<String, dynamic>)['id'] as String;

    // 3. Accept booking
    await tutorRepo.updateBookingStatus(
      bookingId: bookingId,
      status: BookingStatus.awaitingPayment,
      actorUid: tutor.uid,
    );

    // 4. Pay booking to activate sessions
    await studentRepo.processSecureWebhookPayment(
      bookingId: bookingId,
      studentUid: student.uid,
      paymentMethod: 'gopay',
    );

    // 5. Send two chat messages from student to tutor
    // First message starts the conversation
    await studentClient.from('messages').insert({
      'booking_id': bookingId,
      'sender_uid': student.uid,
      'receiver_uid': tutor.uid,
      'body': 'Halo Tutor, ini pesan pertama.',
    });

    // Second message sends content
    await studentClient.from('messages').insert({
      'booking_id': bookingId,
      'sender_uid': student.uid,
      'receiver_uid': tutor.uid,
      'body': 'Halo Tutor, saya sudah membayar untuk kelas Matematika.',
    });

    // 6. Verify app_notifications was generated automatically by database trigger trg_notify_chat_message_insert
    final notifs = await tutorClient
        .from('app_notifications')
        .select()
        .eq('user_uid', tutor.uid)
        .eq('actor_uid', student.uid)
        .eq('category', 'chat')
        .order('created_at', ascending: true);

    expect(notifs.length, equals(2), reason: 'Trigger trg_notify_chat_message_insert gagal membangkitkan notifikasi chat untuk kedua pesan');

    // First notification verification (conversation started)
    final notif1 = notifs[0];
    expect(notif1['title'], equals('Percakapan baru dimulai'));
    expect(notif1['body'], contains('memulai percakapan untuk booking ini'));

    // Second notification verification (message content)
    final notif2 = notifs[1];
    expect(notif2['title'], contains('Chat Student'));
    expect(notif2['body'], contains('Halo Tutor, saya sudah membayar'));

    // 7. Verify push_delivery_queue entries were generated automatically by database trigger trg_enqueue_push_delivery_for_notification
    final notifId1 = notif1['id'] as String;
    final notifId2 = notif2['id'] as String;

    final pushQueue1 = await tutorClient
        .from('push_delivery_queue')
        .select()
        .eq('notification_id', notifId1);
    expect(pushQueue1, isNotEmpty, reason: 'Trigger trg_enqueue_push_delivery_for_notification gagal untuk notifikasi pertama');
    expect(pushQueue1.first['payload']['title'], equals('Percakapan baru dimulai'));

    final pushQueue2 = await tutorClient
        .from('push_delivery_queue')
        .select()
        .eq('notification_id', notifId2);
    expect(pushQueue2, isNotEmpty, reason: 'Trigger trg_enqueue_push_delivery_for_notification gagal untuk notifikasi kedua');
    
    final payload2 = pushQueue2.first['payload'];
    expect(payload2['title'], contains('Chat Student'));
    expect(payload2['body'], contains('Halo Tutor, saya sudah membayar'));
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
