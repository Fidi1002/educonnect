import 'dart:async';

import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/core/utils/resilient_stream.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/session_change_request.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(client: ref.watch(supabaseClientProvider));
});

class BookingRepository {
  BookingRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;
  static const Duration _rescheduleDeadline = Duration(hours: 6);
  static const Duration _lateCancelThreshold = Duration(hours: 12);

  Stream<List<BookingItem>> watchStudentBookings(String studentUid) {
    return resilientStream(
      () => _client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('student_uid', studentUid)
          .order('session_start', ascending: false)
          .map((rows) => rows.map(BookingItem.fromMap).toList()),
    );
  }

  Stream<BookingItem?> watchBookingById(String bookingId) {
    return resilientStream(
      () => _client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('id', bookingId)
          .map((rows) {
            if (rows.isEmpty) {
              return null;
            }
            return BookingItem.fromMap(rows.first);
          }),
    );
  }

  Future<BookingItem?> fetchBookingById(String bookingId) async {
    final row = await _client
        .from('bookings')
        .select(
          'id,student_uid,tutor_uid,subject,session_start,duration_minutes,session_end,status,'
          'message,created_at,total_amount,paid_at,package_months,sessions_per_week,'
          'package_start_date,package_end_date,weekly_schedule',
        )
        .eq('id', bookingId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return BookingItem.fromMap(row);
  }

  Stream<List<BookingItem>> watchTutorBookings(
    String tutorUid, {
    bool pendingOnly = false,
  }) {
    return resilientStream(
      () => _client
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
          }),
    );
  }

  Future<void> createBooking({
    required String studentUid,
    required String tutorUid,
    required String subject,
    required DateTime packageStartDate,
    required int packageMonths,
    required List<BookingWeeklySlot> weeklySlots,
    required int durationMinutes,
    required String message,
  }) async {
    if (weeklySlots.length != 2) {
      throw const PostgrestException(
        message: 'Booking paket wajib memilih 2 jadwal per minggu.',
      );
    }

    final sessionStartLocal = _computeFirstSessionStart(
      packageStartDate: packageStartDate,
      slot: weeklySlots.first,
    );
    final startUtc = sessionStartLocal.toUtc();
    final endUtc = startUtc.add(Duration(minutes: durationMinutes));
    final packageEndDate = DateTime(
      packageStartDate.year,
      packageStartDate.month + packageMonths,
      packageStartDate.day,
    ).subtract(const Duration(days: 1));

    final tutorRow = await _client
        .from('tutors')
        .select('price_per_hour')
        .eq('uid', tutorUid)
        .maybeSingle();
    final pricePerHour = (tutorRow?['price_per_hour'] as num?) ?? 0;
    final sessionPrice = ((pricePerHour * durationMinutes) / 60);
    final sessionCountMonth1 = _countSessionsInRange(
      startDate: packageStartDate,
      endDate: DateTime(
        packageStartDate.year,
        packageStartDate.month + 1,
        packageStartDate.day,
      ).subtract(const Duration(days: 1)),
      slots: weeklySlots,
    );
    final month1Amount = (sessionPrice * sessionCountMonth1).round();

    final transactionPayload = <Map<String, dynamic>>[];
    for (var cycle = 1; cycle <= packageMonths; cycle++) {
      final cycleStart = DateTime(
        packageStartDate.year,
        packageStartDate.month + (cycle - 1),
        packageStartDate.day,
      );
      final cycleEnd = DateTime(
        packageStartDate.year,
        packageStartDate.month + cycle,
        packageStartDate.day,
      ).subtract(const Duration(days: 1));
      final cycleSessionCount = _countSessionsInRange(
        startDate: cycleStart,
        endDate: cycleEnd,
        slots: weeklySlots,
      );
      final amount = (sessionPrice * cycleSessionCount).round();
      transactionPayload.add({
        'student_uid': studentUid,
        'tutor_uid': tutorUid,
        'amount': amount,
        'payment_method': 'dummy',
        'payment_status': 'pending',
        'cycle_number': cycle,
        'due_at': cycleStart.toUtc().toIso8601String(),
      });
    }

    final generatedSessions = _generateSessionsForPackage(
      studentUid: studentUid,
      tutorUid: tutorUid,
      packageStartDate: packageStartDate,
      packageEndDate: packageEndDate,
      weeklySlots: weeklySlots,
      durationMinutes: durationMinutes,
    );

    await _client.rpc(
      'create_booking_with_cycles_and_sessions',
      params: {
        'p_student_uid': studentUid,
        'p_tutor_uid': tutorUid,
        'p_subject': subject.trim(),
        'p_session_start': startUtc.toIso8601String(),
        'p_duration_minutes': durationMinutes,
        'p_session_end': endUtc.toIso8601String(),
        'p_message': message.trim(),
        'p_total_amount': month1Amount,
        'p_package_months': packageMonths,
        'p_sessions_per_week': 2,
        'p_weekly_schedule': weeklySlots.map((slot) => slot.toMap()).toList(),
        'p_package_start_date': _dateOnly(packageStartDate),
        'p_package_end_date': _dateOnly(packageEndDate),
        'p_transactions': transactionPayload,
        'p_sessions': generatedSessions,
      },
    );
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    required String actorUid,
  }) async {
    final bookingRow = await _client
        .from('bookings')
        .select('id,student_uid,tutor_uid')
        .eq('id', bookingId)
        .maybeSingle();
    if (bookingRow == null) {
      throw const PostgrestException(message: 'Booking tidak ditemukan.');
    }

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

    final studentUid = bookingRow['student_uid'] as String? ?? '';
    final tutorUid = bookingRow['tutor_uid'] as String? ?? '';
    final targetUid = actorUid == tutorUid ? studentUid : tutorUid;
    if (targetUid.isEmpty) {
      return;
    }

    final title = switch (status) {
      BookingStatus.awaitingPayment => 'Booking Diterima',
      BookingStatus.rejected => 'Booking Ditolak',
      BookingStatus.completed => 'Booking Selesai',
      BookingStatus.cancelled => 'Booking Dibatalkan',
      BookingStatus.paid => 'Booking Lunas',
      BookingStatus.pending => 'Status Booking Diperbarui',
    };
    final body = switch (status) {
      BookingStatus.awaitingPayment =>
        'Tutor menerima booking kamu. Lanjutkan pembayaran.',
      BookingStatus.rejected =>
        'Tutor menolak booking ini. Kamu bisa pilih tutor lain.',
      BookingStatus.completed =>
        'Sesi sudah ditandai selesai. Cek riwayat untuk detail.',
      BookingStatus.cancelled =>
        'Booking dibatalkan. Silakan cek detail jadwal.',
      BookingStatus.paid => 'Pembayaran booking berhasil.',
      BookingStatus.pending => 'Ada perubahan pada status booking.',
    };

    await _createNotification(
      userUid: targetUid,
      actorUid: actorUid,
      category:
          status == BookingStatus.awaitingPayment ||
              status == BookingStatus.rejected ||
              status == BookingStatus.completed ||
              status == BookingStatus.cancelled
          ? 'booking'
          : 'system',
      title: title,
      body: body,
      targetType: 'booking',
      targetId: bookingId,
    );
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

    final pendingCycleRow = await _client
        .from('transactions')
        .select('id,cycle_number,amount')
        .eq('booking_id', bookingId)
        .eq('student_uid', studentUid)
        .eq('payment_status', 'pending')
        .order('cycle_number')
        .limit(1)
        .maybeSingle();

    if (pendingCycleRow == null) {
      throw const PostgrestException(
        message: 'Tidak ada tagihan aktif yang perlu dibayar.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('bookings')
        .update({
          'status': BookingStatus.paid.value,
          'paid_at': now,
          'total_amount': (pendingCycleRow['amount'] as num?) ?? 0,
          'updated_at': now,
        })
        .eq('id', bookingId);

    await _client
        .from('transactions')
        .update({
          'payment_method': 'dummy',
          'payment_status': 'paid',
          'payment_ref': 'DUMMY-${DateTime.now().millisecondsSinceEpoch}',
          'paid_at': now,
          'updated_at': now,
        })
        .eq('booking_id', bookingId)
        .eq('cycle_number', (pendingCycleRow['cycle_number'] as int?) ?? 1);

    final tutorUid = bookingRow['tutor_uid'] as String? ?? '';
    await _createNotification(
      userUid: tutorUid,
      actorUid: studentUid,
      category: 'payment',
      title: 'Pembayaran Diterima',
      body: 'Murid sudah menyelesaikan pembayaran booking.',
      targetType: 'booking',
      targetId: bookingId,
    );
  }

  Stream<List<BookingSession>> watchBookingSessions(String bookingId) {
    return resilientStream(
      () => _client
          .from('booking_sessions')
          .stream(primaryKey: ['id'])
          .eq('booking_id', bookingId)
          .order('session_start')
          .map((rows) => rows.map(BookingSession.fromMap).toList()),
    );
  }

  Stream<List<BookingSession>> watchStudentBookingSessions(String studentUid) {
    return resilientStream(
      () => _client
          .from('booking_sessions')
          .stream(primaryKey: ['id'])
          .eq('student_uid', studentUid)
          .order('session_start')
          .map((rows) => rows.map(BookingSession.fromMap).toList()),
    );
  }

  Stream<List<BookingSession>> watchTutorBookingSessions(String tutorUid) {
    return resilientStream(
      () => _client
          .from('booking_sessions')
          .stream(primaryKey: ['id'])
          .eq('tutor_uid', tutorUid)
          .order('session_start')
          .map((rows) => rows.map(BookingSession.fromMap).toList()),
    );
  }

  Future<void> processStudentSessionReminders(String studentUid) async {
    await _client.rpc(
      'process_student_session_reminders',
      params: {'p_student_uid': studentUid},
    );
  }

  Stream<List<SessionChangeRequest>> watchBookingSessionChangeRequests(
    String bookingId,
  ) {
    unawaited(_expireStaleSessionChangeRequests(bookingId: bookingId));
    return resilientStream(
      () => _client
          .from('session_change_requests')
          .stream(primaryKey: ['id'])
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .map((rows) => rows.map(SessionChangeRequest.fromMap).toList()),
    );
  }

  Stream<List<SessionLearningRecord>> watchSessionLearningRecords(
    String bookingId,
  ) {
    return resilientStream(
      () => _client
          .from('session_learning_records')
          .stream(primaryKey: ['id'])
          .eq('booking_id', bookingId)
          .order('updated_at', ascending: false)
          .map((rows) => rows.map(SessionLearningRecord.fromMap).toList()),
    );
  }

  Stream<List<SessionLearningRecord>> watchTutorPendingHomeworkRecords(
    String tutorUid,
  ) {
    return resilientStream(
      () => _client
          .from('session_learning_records')
          .stream(primaryKey: ['id'])
          .eq('tutor_uid', tutorUid)
          .order('updated_at', ascending: false)
          .map(
            (rows) => rows
                .map(SessionLearningRecord.fromMap)
                .where(
                  (record) => record.homeworkStatus == HomeworkStatus.submitted,
                )
                .toList(),
          ),
    );
  }

  Future<void> requestSessionReschedule({
    required String sessionId,
    required String requesterUid,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required String reason,
  }) async {
    if (!proposedEnd.isAfter(proposedStart)) {
      throw const PostgrestException(message: 'Waktu reschedule tidak valid.');
    }

    await _expireStaleSessionChangeRequests(sessionId: sessionId);
    final session = await _fetchSessionForChange(sessionId);
    _assertRescheduleWindow(sessionStart: session.sessionStartUtc);
    await _ensureNoPendingChangeRequest(sessionId);

    final studentUid = session.studentUid;
    final tutorUid = session.tutorUid;
    final requesterRole = requesterUid == tutorUid ? 'tutor' : 'student';
    final targetUid = requesterUid == tutorUid ? studentUid : tutorUid;

    await _client.from('session_change_requests').insert({
      'session_id': sessionId,
      'booking_id': session.bookingId,
      'requester_uid': requesterUid,
      'requester_role': requesterRole,
      'target_uid': targetUid,
      'request_type': 'reschedule',
      'reason': reason.trim(),
      'proposed_start': proposedStart.toUtc().toIso8601String(),
      'proposed_end': proposedEnd.toUtc().toIso8601String(),
      'status': 'pending',
    });

    await _createNotification(
      userUid: targetUid,
      actorUid: requesterUid,
      category: 'session_change',
      title: 'Permintaan Reschedule',
      body:
          'Ada permintaan reschedule sesi. Cek jadwal untuk menyetujui atau menolak.',
      targetType: 'booking_session',
      targetId: sessionId,
    );
  }

  Future<void> requestSessionCancel({
    required String sessionId,
    required String requesterUid,
    required String reason,
  }) async {
    await _expireStaleSessionChangeRequests(sessionId: sessionId);
    final session = await _fetchSessionForChange(sessionId);
    await _ensureNoPendingChangeRequest(sessionId);

    final studentUid = session.studentUid;
    final tutorUid = session.tutorUid;
    final requesterRole = requesterUid == tutorUid ? 'tutor' : 'student';
    final targetUid = requesterUid == tutorUid ? studentUid : tutorUid;

    await _client.from('session_change_requests').insert({
      'session_id': sessionId,
      'booking_id': session.bookingId,
      'requester_uid': requesterUid,
      'requester_role': requesterRole,
      'target_uid': targetUid,
      'request_type': 'cancel',
      'reason': reason.trim(),
      'status': 'pending',
    });

    await _createNotification(
      userUid: targetUid,
      actorUid: requesterUid,
      category: 'session_change',
      title: 'Permintaan Pembatalan',
      body: 'Ada permintaan pembatalan sesi. Silakan review keputusanmu.',
      targetType: 'booking_session',
      targetId: sessionId,
    );
  }

  Future<void> respondSessionChangeRequest({
    required String requestId,
    required String reviewerUid,
    required bool approved,
  }) async {
    await _expireStaleSessionChangeRequests();
    final request = await _client
        .from('session_change_requests')
        .select()
        .eq('id', requestId)
        .maybeSingle();
    if (request == null) {
      throw const PostgrestException(
        message: 'Permintaan perubahan tidak ditemukan.',
      );
    }
    final requestStatus = request['status'] as String? ?? 'pending';
    if (requestStatus != 'pending') {
      throw PostgrestException(
        message: requestStatus == 'expired'
            ? 'Permintaan ini sudah kedaluwarsa.'
            : 'Permintaan ini sudah diproses.',
      );
    }
    if ((request['target_uid'] as String?) != reviewerUid) {
      throw const PostgrestException(
        message: 'Kamu bukan pihak yang menyetujui request ini.',
      );
    }

    final expiresAt = DateTime.tryParse(
      request['expires_at'] as String? ?? '',
    )?.toUtc();
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc())) {
      await _expireStaleSessionChangeRequests(
        bookingId: request['booking_id'] as String?,
        sessionId: request['session_id'] as String?,
      );
      throw const PostgrestException(
        message: 'Permintaan sudah kedaluwarsa, silakan buat request baru.',
      );
    }

    final requestType = request['request_type'] as String? ?? '';
    final sessionId = request['session_id'] as String? ?? '';
    final now = DateTime.now().toUtc();

    if (!approved) {
      await _client
          .from('session_change_requests')
          .update({
            'status': 'rejected',
            'reviewed_by_uid': reviewerUid,
            'reviewed_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', requestId);

      await _createNotification(
        userUid: request['requester_uid'] as String? ?? '',
        actorUid: reviewerUid,
        category: 'session_change',
        title: 'Request Ditolak',
        body: 'Permintaan perubahan sesi kamu ditolak.',
        targetType: 'booking_session',
        targetId: sessionId,
      );
      return;
    }

    final session = await _client
        .from('booking_sessions')
        .select(
          'id,booking_id,student_uid,tutor_uid,session_start,session_end,status',
        )
        .eq('id', sessionId)
        .maybeSingle();
    if (session == null) {
      throw const PostgrestException(message: 'Sesi target tidak ditemukan.');
    }

    if (requestType == 'cancel') {
      final sessionStart =
          DateTime.tryParse(
            session['session_start'] as String? ?? '',
          )?.toUtc() ??
          now;
      final isLateCancel = sessionStart.difference(now) < _lateCancelThreshold;
      final cancelledStatus = isLateCancel
          ? BookingSessionStatus.cancelledLate
          : BookingSessionStatus.cancelledEarly;

      await _client
          .from('booking_sessions')
          .update({
            'status': cancelledStatus.value,
            'cancelled_by_role': request['requester_role'] as String?,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', sessionId);
    } else if (requestType == 'reschedule') {
      final sessionStart =
          DateTime.tryParse(
            session['session_start'] as String? ?? '',
          )?.toUtc() ??
          now;
      if (sessionStart.difference(now) < _rescheduleDeadline) {
        await _client
            .from('session_change_requests')
            .update({
              'status': 'rejected',
              'reviewed_by_uid': reviewerUid,
              'reviewed_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('id', requestId);
        throw const PostgrestException(
          message: 'Request reschedule melewati batas waktu minimal H-6.',
        );
      }

      final proposedStart = DateTime.tryParse(
        request['proposed_start'] as String? ?? '',
      )?.toUtc();
      final proposedEnd = DateTime.tryParse(
        request['proposed_end'] as String? ?? '',
      )?.toUtc();
      if (proposedStart == null || proposedEnd == null) {
        throw const PostgrestException(
          message: 'Data waktu reschedule tidak valid.',
        );
      }

      final inserted = await _client
          .from('booking_sessions')
          .insert({
            'booking_id': session['booking_id'] as String,
            'student_uid': session['student_uid'] as String,
            'tutor_uid': session['tutor_uid'] as String,
            'session_start': proposedStart.toIso8601String(),
            'session_end': proposedEnd.toIso8601String(),
            'status': BookingSessionStatus.scheduled.value,
            'rescheduled_from_session_id': sessionId,
          })
          .select('id')
          .single();

      await _client
          .from('booking_sessions')
          .update({
            'status': BookingSessionStatus.rescheduled.value,
            'rescheduled_to_session_id': inserted['id'] as String,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', sessionId);
    }

    await _client
        .from('session_change_requests')
        .update({
          'status': 'approved',
          'reviewed_by_uid': reviewerUid,
          'reviewed_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', requestId);

    await _createNotification(
      userUid: request['requester_uid'] as String? ?? '',
      actorUid: reviewerUid,
      category: 'session_change',
      title: approved ? 'Request Disetujui' : 'Request Ditolak',
      body: approved
          ? 'Permintaan perubahan sesi kamu sudah disetujui.'
          : 'Permintaan perubahan sesi kamu ditolak.',
      targetType: 'booking_session',
      targetId: sessionId,
    );

    await _recalculateTutorConsistency(session['tutor_uid'] as String? ?? '');
  }

  Future<void> markSessionDoneByTutor(String sessionId) async {
    final row = await _client
        .from('booking_sessions')
        .select('id,tutor_uid,session_end')
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) {
      throw const PostgrestException(message: 'Sesi tidak ditemukan.');
    }

    final sessionEnd =
        DateTime.tryParse(row['session_end'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    final nowUtc = DateTime.now().toUtc();
    final tutorMarkedDoneAt = nowUtc.isBefore(sessionEnd) ? sessionEnd : nowUtc;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('booking_sessions')
        .update({
          'status': BookingSessionStatus.donePendingConfirmation.value,
          'tutor_marked_done_at': tutorMarkedDoneAt.toIso8601String(),
          'updated_at': now,
        })
        .eq('id', sessionId);

    await _recalculateTutorConsistency(row['tutor_uid'] as String? ?? '');
  }

  Future<void> confirmSessionByStudent({
    required String sessionId,
    required int? rating,
    required String review,
  }) async {
    final row = await _client
        .from('booking_sessions')
        .select('id,tutor_uid')
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) {
      throw const PostgrestException(message: 'Sesi tidak ditemukan.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('booking_sessions')
        .update({
          'status': BookingSessionStatus.confirmed.value,
          'student_confirmed_at': now,
          'student_rating': rating,
          'student_review': review.trim(),
          'updated_at': now,
        })
        .eq('id', sessionId);

    await _recalculateTutorRating(row['tutor_uid'] as String? ?? '');
    await _recalculateTutorConsistency(row['tutor_uid'] as String? ?? '');
  }

  Future<void> disputeSessionByStudent(String sessionId) async {
    final row = await _client
        .from('booking_sessions')
        .select('id,tutor_uid,student_uid')
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) {
      throw const PostgrestException(message: 'Sesi tidak ditemukan.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('booking_sessions')
        .update({
          'status': BookingSessionStatus.disputedPending.value,
          'updated_at': now,
        })
        .eq('id', sessionId);

    await _createNotification(
      userUid: row['tutor_uid'] as String? ?? '',
      actorUid: row['student_uid'] as String? ?? '',
      category: 'session_change',
      title: 'Sesi Di-dispute Murid',
      body: 'Murid menandai sesi tidak berjalan. Silakan cek detail kelas.',
      targetType: 'booking_session',
      targetId: sessionId,
    );

    await _recalculateTutorConsistency(row['tutor_uid'] as String? ?? '');
  }

  Future<void> resolveDisputeByTutor(String sessionId) async {
    final row = await _client
        .from('booking_sessions')
        .select('id,student_uid,tutor_uid,status')
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) {
      throw const PostgrestException(message: 'Sesi tidak ditemukan.');
    }

    final status = BookingSessionStatusX.fromValue(row['status'] as String?);
    if (status != BookingSessionStatus.disputedPending) {
      throw const PostgrestException(message: 'Sesi ini bukan dispute aktif.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('booking_sessions')
        .update({
          'status': BookingSessionStatus.disputedResolved.value,
          'updated_at': now,
        })
        .eq('id', sessionId);

    await _createNotification(
      userUid: row['student_uid'] as String? ?? '',
      actorUid: row['tutor_uid'] as String? ?? '',
      category: 'session_change',
      title: 'Dispute Ditutup',
      body: 'Tutor telah menutup status dispute untuk sesi ini.',
      targetType: 'booking_session',
      targetId: sessionId,
    );

    await _recalculateTutorConsistency(row['tutor_uid'] as String? ?? '');
  }

  Future<void> confirmSessionPresenceByStudent(String sessionId) async {
    final row = await _client
        .from('booking_sessions')
        .select('id,status,student_presence_confirmed_at')
        .eq('id', sessionId)
        .maybeSingle();
    if (row == null) {
      throw const PostgrestException(message: 'Sesi tidak ditemukan.');
    }

    final status = BookingSessionStatusX.fromValue(row['status'] as String?);
    if (status != BookingSessionStatus.scheduled &&
        status != BookingSessionStatus.donePendingConfirmation) {
      throw const PostgrestException(
        message: 'Konfirmasi hadir hanya untuk sesi terjadwal.',
      );
    }

    if (row['student_presence_confirmed_at'] != null) {
      return;
    }

    await _client
        .from('booking_sessions')
        .update({
          'student_presence_confirmed_at': DateTime.now()
              .toUtc()
              .toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId);
  }

  Future<void> upsertTutorLearningRecord({
    required String bookingId,
    required String sessionId,
    required String tutorUid,
    required String studentUid,
    required String materialSummary,
    required String materialNotes,
    required String homeworkTitle,
    required String homeworkDescription,
  }) async {
    final existing = await _client
        .from('session_learning_records')
        .select('id')
        .eq('session_id', sessionId)
        .maybeSingle();

    final hasHomework = homeworkTitle.trim().isNotEmpty;
    if (existing == null) {
      await _client.from('session_learning_records').insert({
        'booking_id': bookingId,
        'session_id': sessionId,
        'student_uid': studentUid,
        'tutor_uid': tutorUid,
        'material_summary': materialSummary.trim(),
        'material_notes': materialNotes.trim(),
        'homework_title': homeworkTitle.trim(),
        'homework_description': homeworkDescription.trim(),
        'homework_status': hasHomework
            ? HomeworkStatus.assigned.value
            : HomeworkStatus.none.value,
        'homework_assigned_at': hasHomework
            ? DateTime.now().toUtc().toIso8601String()
            : null,
      });
      return;
    }

    await _client
        .from('session_learning_records')
        .update({
          'material_summary': materialSummary.trim(),
          'material_notes': materialNotes.trim(),
          'homework_title': homeworkTitle.trim(),
          'homework_description': homeworkDescription.trim(),
          'homework_status': hasHomework
              ? HomeworkStatus.assigned.value
              : HomeworkStatus.none.value,
          'homework_assigned_at': hasHomework
              ? DateTime.now().toUtc().toIso8601String()
              : null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', existing['id'] as String? ?? '');
  }

  Future<void> submitHomeworkByStudent({
    required String sessionId,
    required String submissionText,
  }) async {
    final existing = await _client
        .from('session_learning_records')
        .select('id')
        .eq('session_id', sessionId)
        .maybeSingle();
    if (existing == null) {
      throw const PostgrestException(
        message: 'PR untuk sesi ini belum tersedia.',
      );
    }

    await _client
        .from('session_learning_records')
        .update({
          'homework_status': HomeworkStatus.submitted.value,
          'student_submission': submissionText.trim(),
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', existing['id'] as String? ?? '');
  }

  Future<void> markHomeworkReviewedByTutor({required String sessionId}) async {
    final existing = await _client
        .from('session_learning_records')
        .select('id')
        .eq('session_id', sessionId)
        .maybeSingle();
    if (existing == null) {
      throw const PostgrestException(message: 'Record PR tidak ditemukan.');
    }

    await _client
        .from('session_learning_records')
        .update({
          'homework_status': HomeworkStatus.reviewed.value,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', existing['id'] as String? ?? '');
  }

  Future<void> _ensureNoPendingChangeRequest(String sessionId) async {
    await _expireStaleSessionChangeRequests(sessionId: sessionId);
    final existing = await _client
        .from('session_change_requests')
        .select('id')
        .eq('session_id', sessionId)
        .eq('status', 'pending')
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      throw const PostgrestException(
        message: 'Sudah ada request perubahan sesi yang masih pending.',
      );
    }
  }

  Future<void> _expireStaleSessionChangeRequests({
    String? bookingId,
    String? sessionId,
  }) async {
    try {
      await _client.rpc(
        'expire_stale_session_change_requests',
        params: {'p_booking_id': bookingId, 'p_session_id': sessionId},
      );
    } on PostgrestException {
      // Keep main flow resilient if cleanup RPC is temporarily unavailable.
    }
  }

  void _assertRescheduleWindow({required DateTime sessionStart}) {
    final now = DateTime.now().toUtc();
    if (sessionStart.difference(now) < _rescheduleDeadline) {
      throw const PostgrestException(
        message: 'Request reschedule harus diajukan minimal H-6 sebelum sesi.',
      );
    }
  }

  Future<_SessionChangeContext> _fetchSessionForChange(String sessionId) async {
    final session = await _client
        .from('booking_sessions')
        .select('id,booking_id,student_uid,tutor_uid,session_start,status')
        .eq('id', sessionId)
        .maybeSingle();
    if (session == null) {
      throw const PostgrestException(message: 'Sesi tidak ditemukan.');
    }

    final status = BookingSessionStatusX.fromValue(
      session['status'] as String?,
    );
    if (status != BookingSessionStatus.scheduled) {
      throw const PostgrestException(
        message:
            'Perubahan hanya bisa diajukan pada sesi yang masih terjadwal.',
      );
    }

    final sessionStart =
        DateTime.tryParse(session['session_start'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    if (!sessionStart.isAfter(DateTime.now().toUtc())) {
      throw const PostgrestException(
        message: 'Sesi sudah lewat, tidak bisa diajukan perubahan.',
      );
    }

    return _SessionChangeContext(
      bookingId: session['booking_id'] as String? ?? '',
      studentUid: session['student_uid'] as String? ?? '',
      tutorUid: session['tutor_uid'] as String? ?? '',
      sessionStartUtc: sessionStart,
    );
  }

  Future<void> _recalculateTutorRating(String tutorUid) async {
    if (tutorUid.isEmpty) {
      return;
    }
    final ratedRows = await _client
        .from('booking_sessions')
        .select('student_rating')
        .eq('tutor_uid', tutorUid)
        .eq('status', BookingSessionStatus.confirmed.value)
        .not('student_rating', 'is', null);
    final ratings = (ratedRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => row['student_rating'] as int?)
        .whereType<int>()
        .toList(growable: false);
    if (ratings.isEmpty) {
      return;
    }
    final total = ratings.fold<int>(0, (sum, item) => sum + item);
    final average = total / ratings.length;

    await _client
        .from('tutors')
        .update({
          'rating': average,
          'total_reviews': ratings.length,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('uid', tutorUid);
  }

  Future<void> _recalculateTutorConsistency(String tutorUid) async {
    if (tutorUid.isEmpty) {
      return;
    }

    final rows = await _client
        .from('booking_sessions')
        .select('status,tutor_marked_done_at,session_end,cancelled_by_role')
        .eq('tutor_uid', tutorUid);

    final now = DateTime.now().toUtc();
    final sessions = (rows as List<dynamic>).whereType<Map<String, dynamic>>();
    var expectedCount = 0;
    var attendanceCount = 0;
    var onTimeCount = 0;
    var cancelledByTutorCount = 0;

    for (final row in sessions) {
      final sessionEnd = DateTime.tryParse(
        row['session_end'] as String? ?? '',
      )?.toUtc();
      if (sessionEnd == null || sessionEnd.isAfter(now)) {
        continue;
      }
      expectedCount += 1;

      final status = BookingSessionStatusX.fromValue(row['status'] as String?);
      final cancelledByRole = row['cancelled_by_role'] as String? ?? '';
      if (status == BookingSessionStatus.cancelledByTutor ||
          status == BookingSessionStatus.tutorNoShow ||
          ((status == BookingSessionStatus.cancelledEarly ||
                  status == BookingSessionStatus.cancelledLate) &&
              cancelledByRole == 'tutor')) {
        cancelledByTutorCount += 1;
      }

      final attended =
          status == BookingSessionStatus.donePendingConfirmation ||
          status == BookingSessionStatus.confirmed ||
          status == BookingSessionStatus.disputedResolved ||
          status == BookingSessionStatus.studentNoShow;
      if (!attended) {
        continue;
      }

      attendanceCount += 1;
      final markedDoneAt = DateTime.tryParse(
        row['tutor_marked_done_at'] as String? ?? '',
      )?.toUtc();
      if (markedDoneAt == null) {
        continue;
      }
      final onTimeDeadline = sessionEnd.add(const Duration(minutes: 30));
      if (!markedDoneAt.isAfter(onTimeDeadline)) {
        onTimeCount += 1;
      }
    }

    if (expectedCount == 0) {
      await _client
          .from('tutors')
          .update({
            'attendance_rate': 0,
            'on_time_rate': 0,
            'cancellation_rate': 0,
            'consistency_score': 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', tutorUid);
      return;
    }

    final attendanceRate = attendanceCount / expectedCount;
    final onTimeRate = onTimeCount / expectedCount;
    final cancellationRate = cancelledByTutorCount / expectedCount;
    final consistencyScore =
        ((attendanceRate * 0.5) +
            (onTimeRate * 0.3) +
            ((1 - cancellationRate) * 0.2)) *
        100;

    await _client
        .from('tutors')
        .update({
          'attendance_rate': attendanceRate,
          'on_time_rate': onTimeRate,
          'cancellation_rate': cancellationRate,
          'consistency_score': consistencyScore,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('uid', tutorUid);
  }

  List<Map<String, dynamic>> _generateSessionsForPackage({
    required String studentUid,
    required String tutorUid,
    required DateTime packageStartDate,
    required DateTime packageEndDate,
    required List<BookingWeeklySlot> weeklySlots,
    required int durationMinutes,
  }) {
    final start = DateTime(
      packageStartDate.year,
      packageStartDate.month,
      packageStartDate.day,
    );
    final end = DateTime(
      packageEndDate.year,
      packageEndDate.month,
      packageEndDate.day,
      23,
      59,
      59,
    );
    final sessions = <Map<String, dynamic>>[];

    for (final slot in weeklySlots) {
      final hm = _parseHm(slot.startTime);
      var cursor = start;
      final offset = (slot.weekday - cursor.weekday + 7) % 7;
      cursor = cursor.add(Duration(days: offset));

      while (!cursor.isAfter(end)) {
        final sessionStart = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          hm.$1,
          hm.$2,
        );
        final sessionEnd = sessionStart.add(Duration(minutes: durationMinutes));
        sessions.add({
          'student_uid': studentUid,
          'tutor_uid': tutorUid,
          'session_start': sessionStart.toUtc().toIso8601String(),
          'session_end': sessionEnd.toUtc().toIso8601String(),
          'status': BookingSessionStatus.scheduled.value,
        });
        cursor = cursor.add(const Duration(days: 7));
      }
    }

    sessions.sort((a, b) {
      final left = DateTime.parse(a['session_start'] as String);
      final right = DateTime.parse(b['session_start'] as String);
      return left.compareTo(right);
    });
    return sessions;
  }

  DateTime _computeFirstSessionStart({
    required DateTime packageStartDate,
    required BookingWeeklySlot slot,
  }) {
    final baseDate = DateTime(
      packageStartDate.year,
      packageStartDate.month,
      packageStartDate.day,
    );
    final hm = _parseHm(slot.startTime);
    final weekdayDiff = (slot.weekday - baseDate.weekday + 7) % 7;
    final firstDate = baseDate.add(Duration(days: weekdayDiff));
    return DateTime(
      firstDate.year,
      firstDate.month,
      firstDate.day,
      hm.$1,
      hm.$2,
    );
  }

  int _countSessionsInRange({
    required DateTime startDate,
    required DateTime endDate,
    required List<BookingWeeklySlot> slots,
  }) {
    var count = 0;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    for (final slot in slots) {
      var cursor = start;
      final offset = (slot.weekday - cursor.weekday + 7) % 7;
      cursor = cursor.add(Duration(days: offset));
      while (!cursor.isAfter(end)) {
        count += 1;
        cursor = cursor.add(const Duration(days: 7));
      }
    }
    return count;
  }

  String _dateOnly(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.toIso8601String().substring(0, 10);
  }

  (int, int) _parseHm(String value) {
    final split = value.split(':');
    final hour = split.isNotEmpty ? int.tryParse(split[0]) ?? 0 : 0;
    final minute = split.length > 1 ? int.tryParse(split[1]) ?? 0 : 0;
    return (hour, minute);
  }

  Future<void> _createNotification({
    required String userUid,
    required String actorUid,
    required String category,
    required String title,
    required String body,
    required String targetType,
    required String targetId,
  }) async {
    if (userUid.isEmpty || actorUid.isEmpty) {
      return;
    }
    await _client.from('app_notifications').insert({
      'user_uid': userUid,
      'actor_uid': actorUid,
      'category': category,
      'title': title,
      'body': body,
      'target_type': targetType,
      'target_id': targetId,
      'is_read': false,
    });
  }
}

class _SessionChangeContext {
  const _SessionChangeContext({
    required this.bookingId,
    required this.studentUid,
    required this.tutorUid,
    required this.sessionStartUtc,
  });

  final String bookingId;
  final String studentUid;
  final String tutorUid;
  final DateTime sessionStartUtc;
}
