enum PayoutStatus {
  pending,
  approved,
  rejected,
  completed,
}

extension PayoutStatusX on PayoutStatus {
  String get value {
    switch (this) {
      case PayoutStatus.pending:
        return 'pending';
      case PayoutStatus.approved:
        return 'approved';
      case PayoutStatus.rejected:
        return 'rejected';
      case PayoutStatus.completed:
        return 'completed';
    }
  }

  static PayoutStatus fromValue(String? value) {
    switch (value) {
      case 'approved':
        return PayoutStatus.approved;
      case 'rejected':
        return PayoutStatus.rejected;
      case 'completed':
        return PayoutStatus.completed;
      case 'pending':
      default:
        return PayoutStatus.pending;
    }
  }
}

class PayoutRequest {
  const PayoutRequest({
    required this.id,
    required this.tutorUid,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.rejectionReason,
  });

  final String id;
  final String tutorUid;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final PayoutStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? rejectionReason;

  factory PayoutRequest.fromMap(Map<String, dynamic> map) {
    return PayoutRequest(
      id: map['id'] as String,
      tutorUid: map['tutor_uid'] as String,
      amount: (map['amount'] as num).toDouble(),
      bankName: map['bank_name'] as String? ?? '',
      accountNumber: map['account_number'] as String? ?? '',
      accountHolder: map['account_holder'] as String? ?? '',
      status: PayoutStatusX.fromValue(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'] as String).toLocal()
          : null,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tutor_uid': tutorUid,
      'amount': amount,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_holder': accountHolder,
      'status': status.value,
      'created_at': createdAt.toUtc().toIso8601String(),
      'processed_at': processedAt?.toUtc().toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }
}
