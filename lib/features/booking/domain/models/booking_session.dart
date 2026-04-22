import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';

class BookingSession {
  const BookingSession({
    required this.id,
    required this.bookingId,
    required this.studentUid,
    required this.tutorUid,
    required this.sessionStart,
    required this.sessionEnd,
    required this.status,
    required this.studentRating,
    required this.studentReview,
    required this.cancelledByRole,
    required this.studentPresenceConfirmedAt,
  });

  final String id;
  final String bookingId;
  final String studentUid;
  final String tutorUid;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final BookingSessionStatus status;
  final int? studentRating;
  final String studentReview;
  final String? cancelledByRole;
  final DateTime? studentPresenceConfirmedAt;

  factory BookingSession.fromMap(Map<String, dynamic> map) {
    return BookingSession(
      id: (map['id'] as String?) ?? '',
      bookingId: (map['booking_id'] as String?) ?? '',
      studentUid: (map['student_uid'] as String?) ?? '',
      tutorUid: (map['tutor_uid'] as String?) ?? '',
      sessionStart:
          DateTime.tryParse(map['session_start'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      sessionEnd:
          DateTime.tryParse(map['session_end'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      status: BookingSessionStatusX.fromValue(map['status'] as String?),
      studentRating: map['student_rating'] as int?,
      studentReview: (map['student_review'] as String?) ?? '',
      cancelledByRole: map['cancelled_by_role'] as String?,
      studentPresenceConfirmedAt: DateTime.tryParse(
        map['student_presence_confirmed_at'] as String? ?? '',
      )?.toLocal(),
    );
  }
}
