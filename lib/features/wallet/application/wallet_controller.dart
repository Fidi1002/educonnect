import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/wallet/data/repositories/wallet_repository.dart';
import 'package:educonnect/features/wallet/domain/models/payout_request.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_balance.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletLoadingProvider = StateProvider<bool>((ref) => false);

final walletBalanceProvider = StreamProvider.autoDispose<WalletBalance>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(WalletBalance.empty());
  }
  return ref.watch(walletRepositoryProvider).watchWalletBalance(user.uid);
});

final walletTransactionsProvider =
    StreamProvider.autoDispose<List<WalletTransaction>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(walletRepositoryProvider).watchTransactions(user.uid);
});

final payoutRequestsProvider =
    StreamProvider.autoDispose<List<PayoutRequest>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(walletRepositoryProvider).watchPayoutRequests(user.uid);
});

final walletControllerProvider = Provider<WalletController>((ref) {
  return WalletController(ref);
});

class WalletController {
  WalletController(this._ref);

  final Ref _ref;

  WalletRepository get _repository => _ref.read(walletRepositoryProvider);

  String _requireUid() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('User belum login.');
    }
    return user.uid;
  }

  Future<void> requestPayout({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    final tutorUid = _requireUid();

    _ref.read(walletLoadingProvider.notifier).state = true;
    try {
      await _repository.requestPayout(
        tutorUid: tutorUid,
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolder: accountHolder,
      );
    } finally {
      _ref.read(walletLoadingProvider.notifier).state = false;
    }
  }

  Future<void> simulatePayoutAdminAction(
    String requestId,
    String status, {
    String? reason,
  }) async {
    _ref.read(walletLoadingProvider.notifier).state = true;
    try {
      await _repository.simulatePayoutAdminAction(requestId, status, reason: reason);
    } finally {
      _ref.read(walletLoadingProvider.notifier).state = false;
    }
  }
}
