enum TransactionType {
  credit,
  debit,
}

extension TransactionTypeX on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.credit:
        return 'credit';
      case TransactionType.debit:
        return 'debit';
    }
  }

  static TransactionType fromValue(String? value) {
    switch (value) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
        return TransactionType.debit;
      default:
        throw ArgumentError('Invalid TransactionType: $value');
    }
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.tutorUid,
    required this.amount,
    required this.type,
    required this.description,
    required this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  final String id;
  final String tutorUid;
  final double amount;
  final TransactionType type;
  final String description;
  final String referenceType; // e.g., 'booking', 'payout'
  final String? referenceId;
  final DateTime createdAt;

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] as String,
      tutorUid: map['tutor_uid'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionTypeX.fromValue(map['type'] as String?),
      description: map['description'] as String? ?? '',
      referenceType: map['reference_type'] as String? ?? '',
      referenceId: map['reference_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tutor_uid': tutorUid,
      'amount': amount,
      'type': type.value,
      'description': description,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
