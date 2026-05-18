class WalletBalance {
  const WalletBalance({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
  });

  final double availableBalance;
  final double pendingBalance; // Balance currently in requested payouts
  final double totalEarned; // Total historical earnings

  factory WalletBalance.fromMap(Map<String, dynamic> map) {
    return WalletBalance(
      availableBalance: (map['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (map['pending_balance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (map['total_earned'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory WalletBalance.empty() => const WalletBalance(
        availableBalance: 0.0,
        pendingBalance: 0.0,
        totalEarned: 0.0,
      );

  Map<String, dynamic> toMap() {
    return {
      'available_balance': availableBalance,
      'pending_balance': pendingBalance,
      'total_earned': totalEarned,
    };
  }
}
