import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/wallet/application/wallet_controller.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_transaction.dart';
import 'package:educonnect/features/wallet/presentation/widgets/request_payout_sheet.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TutorWalletPage extends ConsumerWidget {
  const TutorWalletPage({super.key});

  static const routeName = 'tutor-wallet';
  static const routePath = '/tutor/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dompet & Penghasilan')),
      body: balanceAsync.when(
        data: (balance) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: TutorUi.heroGradientPrimary,
                      boxShadow: const [TutorUi.mediumShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Tersedia',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${balance.availableBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saldo Tertahan (Pending)',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp ${balance.pendingBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: balance.availableBalance > 0
                                  ? () => RequestPayoutSheet.show(
                                      context, balance.availableBalance)
                                  : null,
                              icon: const Icon(FluentIcons.money_24_regular,
                                  size: 18),
                              label: const Text('Tarik Dana'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF4B176E),
                                disabledBackgroundColor: Colors.white38,
                                disabledForegroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Riwayat Transaksi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          message: 'Belum ada transaksi',
                          hint: 'Penghasilan dari sesi selesai akan muncul di sini',
                          icon: FluentIcons.wallet_24_regular,
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = transactions[index];
                        final isCredit = tx.type == TransactionType.credit;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCredit ? TutorUi.mint : TutorUi.rose,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit
                                  ? FluentIcons.arrow_down_24_regular
                                  : FluentIcons.arrow_up_24_regular,
                              color: isCredit
                                  ? const Color(0xFF206A42) // Gelap mint
                                  : const Color(0xFFA6334A), // Gelap rose
                            ),
                          ),
                          title: Text(
                            tx.description.isEmpty
                                ? (isCredit ? 'Penerimaan Dana' : 'Penarikan Dana')
                                : tx.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${isCredit ? '+' : '-'} Rp ${tx.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isCredit
                                  ? const Color(0xFF206A42)
                                  : const Color(0xFFA6334A),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Gagal memuat transaksi: $err')),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(message: 'Memuat Dompet...', fullScreen: false),
        error: (err, _) => AppErrorState(
          message: 'Gagal memuat Dompet',
          detail: err.toString(),
          onRetry: () => ref.invalidate(walletBalanceProvider),
        ),
      ),
    );
  }
}
