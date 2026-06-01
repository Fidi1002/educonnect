class StudentTransaction {
  const StudentTransaction({
    required this.id,
    required this.bookingId,
    required this.studentUid,
    required this.tutorUid,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentRef,
    required this.paidAt,
    required this.cycleNumber,
    required this.dueAt,
    required this.createdAt,
    required this.tutorName,
    required this.subject,
  });

  final String id;
  final String bookingId;
  final String studentUid;
  final String tutorUid;
  final num amount;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentRef;
  final DateTime? paidAt;
  final int cycleNumber;
  final DateTime? dueAt;
  final DateTime createdAt;
  final String tutorName;
  final String subject;

  factory StudentTransaction.fromMap(Map<String, dynamic> map) {
    final tutor = map['tutor'] as Map<String, dynamic>?;
    final booking = map['booking'] as Map<String, dynamic>?;
    return StudentTransaction(
      id: (map['id'] as String?) ?? '',
      bookingId: (map['booking_id'] as String?) ?? '',
      studentUid: (map['student_uid'] as String?) ?? '',
      tutorUid: (map['tutor_uid'] as String?) ?? '',
      amount: (map['amount'] as num?) ?? 0,
      paymentMethod: (map['payment_method'] as String?) ?? 'dummy',
      paymentStatus: (map['payment_status'] as String?) ?? 'pending',
      paymentRef: (map['payment_ref'] as String?) ?? '',
      paidAt: DateTime.tryParse(map['paid_at'] as String? ?? '')?.toLocal(),
      cycleNumber: (map['cycle_number'] as int?) ?? 1,
      dueAt: DateTime.tryParse(map['due_at'] as String? ?? '')?.toLocal(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      tutorName: (tutor?['display_name'] as String?) ?? 'Tutor',
      subject: (booking?['subject'] as String?) ?? 'Bimbingan Belajar',
    );
  }
}
