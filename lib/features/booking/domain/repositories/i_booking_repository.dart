import 'dart:io';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/session_change_request.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/student_transaction.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';

abstract class IBookingRepository {
  Stream<List<BookingItem>> watchStudentBookings(String studentUid);
  Stream<BookingItem?> watchBookingById(String bookingId);
  Future<BookingItem?> fetchBookingById(String bookingId);
  Stream<List<BookingItem>> watchTutorBookings(
    String tutorUid, {
    bool pendingOnly = false,
  });

  Future<void> createBooking({
    required String studentUid,
    required String tutorUid,
    required String subject,
    required DateTime packageStartDate,
    required int packageMonths,
    required List<BookingWeeklySlot> weeklySlots,
    required int durationMinutes,
    required String message,
    String meetingType = 'online',
    String meetingLocation = 'Online Classroom',
  });

  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    required String actorUid,
  });

  Future<void> processSecureWebhookPayment({
    required String bookingId,
    required String studentUid,
    required String paymentMethod,
  });

  Stream<List<BookingSession>> watchBookingSessions(String bookingId);
  Stream<List<BookingSession>> watchStudentBookingSessions(String studentUid);
  Stream<List<BookingSession>> watchTutorBookingSessions(String tutorUid);
  
  Future<void> processStudentSessionReminders(String studentUid);
  Future<void> processAutoConfirmSessions();

  Stream<List<SessionChangeRequest>> watchBookingSessionChangeRequests(String bookingId);
  Stream<List<SessionLearningRecord>> watchSessionLearningRecords(String bookingId);
  Stream<List<SessionLearningRecord>> watchStudentLearningRecords(String studentUid);
  Stream<List<SessionLearningRecord>> watchTutorPendingHomeworkRecords(String tutorUid);

  Future<void> requestSessionReschedule({
    required String sessionId,
    required String requesterUid,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    required String reason,
  });

  Future<void> requestSessionCancel({
    required String sessionId,
    required String requesterUid,
    required String reason,
  });

  Future<void> respondSessionChangeRequest({
    required String requestId,
    required String reviewerUid,
    required bool approved,
  });

  Future<void> markSessionStartedByTutor(String sessionId);
  Future<void> markSessionDoneByTutor(String sessionId, {File? photoFile});
  Future<void> markStudentNoShowByTutor(String sessionId);
  Future<void> markTutorNoShowByStudent(String sessionId);
  
  Future<void> confirmSessionByStudent({
    required String sessionId,
    required int? rating,
    required String review,
  });

  Future<void> disputeSessionByStudent(String sessionId);
  Future<void> resolveDisputeByTutor(String sessionId);
  Future<void> confirmSessionPresenceByStudent(String sessionId);

  Future<void> upsertTutorLearningRecord({
    required String bookingId,
    required String sessionId,
    required String tutorUid,
    required String studentUid,
    required String materialSummary,
    required String materialNotes,
    required String homeworkTitle,
    required String homeworkDescription,
  });

  Future<void> submitHomeworkByStudent({
    required String sessionId,
    required String submissionText,
  });

  Future<void> markHomeworkReviewedByTutor({required String sessionId, required String feedback, required int? grade});

  Future<int> getRescheduleCountInLast30Days(String bookingId);

  Future<List<StudentTransaction>> fetchStudentTransactions(String studentUid);

  Future<List<BookingWeeklySlot>> fetchBookedWeeklySlots(String tutorUid);

  Future<void> checkSessionEndNotifications();
  Future<BookingSession?> fetchSessionById(String sessionId);
}

