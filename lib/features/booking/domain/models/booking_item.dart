import 'package:educonnect/features/booking/domain/models/booking_status.dart';

class BookingItem {
  const BookingItem({
    required this.id,
    required this.studentUid,
    required this.tutorUid,
    required this.subject,
    required this.sessionStart,
    required this.durationMinutes,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.totalAmount,
    required this.paidAt,
    required this.studentName,
    required this.tutorName,
  });

  final String id;
  final String studentUid;
  final String tutorUid;
  final String subject;
  final DateTime sessionStart;
  final int durationMinutes;
  final BookingStatus status;
  final String message;
  final DateTime createdAt;
  final num totalAmount;
  final DateTime? paidAt;
  final String studentName;
  final String tutorName;

  DateTime get sessionEnd =>
      sessionStart.add(Duration(minutes: durationMinutes));

  factory BookingItem.fromMap(Map<String, dynamic> map) {
    final student = map['student'] as Map<String, dynamic>?;
    final tutor = map['tutor'] as Map<String, dynamic>?;
    return BookingItem(
      id: (map['id'] as String?) ?? '',
      studentUid: (map['student_uid'] as String?) ?? '',
      tutorUid: (map['tutor_uid'] as String?) ?? '',
      subject: (map['subject'] as String?) ?? '-',
      sessionStart:
          DateTime.tryParse(map['session_start'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      durationMinutes: (map['duration_minutes'] as int?) ?? 60,
      status: BookingStatusX.fromValue(map['status'] as String?),
      message: (map['message'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      totalAmount: (map['total_amount'] as num?) ?? 0,
      paidAt: DateTime.tryParse(map['paid_at'] as String? ?? '')?.toLocal(),
      studentName: (student?['display_name'] as String?) ?? 'Murid',
      tutorName: (tutor?['display_name'] as String?) ?? 'Tutor',
    );
  }
}
