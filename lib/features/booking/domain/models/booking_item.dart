import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';

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
    required this.packageMonths,
    required this.sessionsPerWeek,
    required this.packageStartDate,
    required this.packageEndDate,
    required this.weeklySchedule,
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
  final int packageMonths;
  final int sessionsPerWeek;
  final DateTime packageStartDate;
  final DateTime packageEndDate;
  final List<BookingWeeklySlot> weeklySchedule;

  DateTime get sessionEnd =>
      sessionStart.add(Duration(minutes: durationMinutes));

  factory BookingItem.fromMap(Map<String, dynamic> map) {
    final student = map['student'] as Map<String, dynamic>?;
    final tutor = map['tutor'] as Map<String, dynamic>?;
    final weeklyScheduleRaw = map['weekly_schedule'] as List<dynamic>? ?? [];
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
      packageMonths: (map['package_months'] as int?) ?? 1,
      sessionsPerWeek: (map['sessions_per_week'] as int?) ?? 2,
      packageStartDate:
          DateTime.tryParse(
            map['package_start_date'] as String? ?? '',
          )?.toLocal() ??
          DateTime.now(),
      packageEndDate:
          DateTime.tryParse(
            map['package_end_date'] as String? ?? '',
          )?.toLocal() ??
          DateTime.now().add(const Duration(days: 30)),
      weeklySchedule: weeklyScheduleRaw
          .whereType<Map<String, dynamic>>()
          .map(BookingWeeklySlot.fromMap)
          .toList(growable: false),
    );
  }
}
