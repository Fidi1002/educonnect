import 'dart:async';

import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/core/utils/resilient_stream.dart';
import 'package:educonnect/features/wallet/domain/models/payout_request.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_balance.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(client: ref.watch(supabaseClientProvider));
});

class WalletRepository {
  WalletRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Stream<WalletBalance> watchWalletBalance(String tutorUid) {
    return resilientStream(
      () => _client
          .from('tutor_wallets')
          .stream(primaryKey: ['tutor_uid'])
          .eq('tutor_uid', tutorUid)
          .map((rows) {
            if (rows.isEmpty) {
              return WalletBalance.empty();
            }
            return WalletBalance.fromMap(rows.first);
          }),
    );
  }

  Stream<List<WalletTransaction>> watchTransactions(String tutorUid) {
    return resilientStream(
      () => _client
          .from('wallet_transactions')
          .stream(primaryKey: ['id'])
          .eq('tutor_uid', tutorUid)
          .order('created_at', ascending: false)
          .map((rows) => rows.map(WalletTransaction.fromMap).toList()),
    );
  }

  Stream<List<PayoutRequest>> watchPayoutRequests(String tutorUid) {
    return resilientStream(
      () => _client
          .from('payout_requests')
          .stream(primaryKey: ['id'])
          .eq('tutor_uid', tutorUid)
          .order('created_at', ascending: false)
          .map((rows) => rows.map(PayoutRequest.fromMap).toList()),
    );
  }

  Future<void> requestPayout({
    required String tutorUid,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    if (amount <= 0) {
      throw const PostgrestException(message: 'Jumlah penarikan tidak valid.');
    }

    await _client.rpc('request_tutor_payout', params: {
      'p_tutor_uid': tutorUid,
      'p_amount': amount,
      'p_bank_name': bankName,
      'p_account_number': accountNumber,
      'p_account_holder': accountHolder,
    });
  }
}
