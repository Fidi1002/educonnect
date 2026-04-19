import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(client: ref.watch(supabaseClientProvider));
});

class BookingRepository {
  BookingRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Stream<List<BookingItem>> watchStudentBookings(String studentUid) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('student_uid', studentUid)
        .order('session_start', ascending: false)
        .map((rows) => rows.map(BookingItem.fromMap).toList());
  }

  Stream<BookingItem?> watchBookingById(String bookingId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .map((rows) {
          if (rows.isEmpty) {
            return null;
          }
          return BookingItem.fromMap(rows.first);
        });
  }

  Stream<List<BookingItem>> watchTutorBookings(
    String tutorUid, {
    bool pendingOnly = false,
  }) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('tutor_uid', tutorUid)
        .order('session_start', ascending: false)
        .map((rows) {
          final mapped = rows.map(BookingItem.fromMap).toList();
          if (!pendingOnly) {
            return mapped;
          }
          return mapped
              .where((item) => item.status == BookingStatus.pending)
              .toList();
        });
  }

  Future<void> createBooking({
    required String studentUid,
    required String tutorUid,
    required String subject,
    required DateTime sessionStart,
    required int durationMinutes,
    required String message,
  }) async {
    final startUtc = sessionStart.toUtc();
    final endUtc = startUtc.add(Duration(minutes: durationMinutes));

    final conflictRows = await _client
        .from('bookings')
        .select('id')
        .eq('tutor_uid', tutorUid)
        .inFilter('status', <String>[
          BookingStatus.pending.value,
          BookingStatus.awaitingPayment.value,
          BookingStatus.paid.value,
        ])
        .lt('session_start', endUtc.toIso8601String())
        .gt('session_end', startUtc.toIso8601String());

    if ((conflictRows as List<dynamic>).isNotEmpty) {
      throw const PostgrestException(
        message: 'Jadwal tutor bentrok dengan booking lain.',
      );
    }

    final tutorRow = await _client
        .from('tutors')
        .select('price_per_hour')
        .eq('uid', tutorUid)
        .maybeSingle();
    final pricePerHour = (tutorRow?['price_per_hour'] as num?) ?? 0;
    final totalAmount = ((pricePerHour * durationMinutes) / 60).round();

    final inserted = await _client
        .from('bookings')
        .insert({
          'student_uid': studentUid,
          'tutor_uid': tutorUid,
          'subject': subject.trim(),
          'session_start': startUtc.toIso8601String(),
          'duration_minutes': durationMinutes,
          'session_end': endUtc.toIso8601String(),
          'status': BookingStatus.pending.value,
          'message': message.trim(),
          'total_amount': totalAmount,
        })
        .select('id')
        .single();

    await _client.from('transactions').upsert({
      'booking_id': inserted['id'] as String,
      'student_uid': studentUid,
      'tutor_uid': tutorUid,
      'amount': totalAmount,
      'payment_method': 'dummy',
      'payment_status': 'pending',
    }, onConflict: 'booking_id');
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    await _client
        .from('bookings')
        .update({
          'status': status.value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', bookingId);

    if (status == BookingStatus.awaitingPayment) {
      await _client
          .from('transactions')
          .update({
            'payment_status': 'pending',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('booking_id', bookingId);
    }
  }

  Future<void> completeDummyPayment({
    required String bookingId,
    required String studentUid,
  }) async {
    final bookingRow = await _client
        .from('bookings')
        .select('id,student_uid,status,total_amount,tutor_uid')
        .eq('id', bookingId)
        .maybeSingle();

    if (bookingRow == null) {
      throw const PostgrestException(message: 'Booking tidak ditemukan.');
    }

    if ((bookingRow['student_uid'] as String?) != studentUid) {
      throw const PostgrestException(message: 'Booking ini bukan milik kamu.');
    }

    final status = BookingStatusX.fromValue(bookingRow['status'] as String?);
    if (status != BookingStatus.awaitingPayment) {
      throw const PostgrestException(
        message: 'Booking belum siap dibayar atau sudah diproses.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('bookings')
        .update({
          'status': BookingStatus.paid.value,
          'paid_at': now,
          'updated_at': now,
        })
        .eq('id', bookingId);

    await _client.from('transactions').upsert({
      'booking_id': bookingId,
      'student_uid': studentUid,
      'tutor_uid': bookingRow['tutor_uid'] as String,
      'amount': (bookingRow['total_amount'] as num?) ?? 0,
      'payment_method': 'dummy',
      'payment_status': 'paid',
      'payment_ref': 'DUMMY-${DateTime.now().millisecondsSinceEpoch}',
      'paid_at': now,
      'updated_at': now,
    }, onConflict: 'booking_id');
  }
}
