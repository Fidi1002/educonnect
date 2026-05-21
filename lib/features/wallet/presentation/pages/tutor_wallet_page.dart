import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/wallet/application/wallet_controller.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_transaction.dart';
import 'package:educonnect/features/wallet/domain/models/payout_request.dart';
import 'package:educonnect/features/wallet/presentation/widgets/request_payout_sheet.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TutorWalletPage extends ConsumerStatefulWidget {
  const TutorWalletPage({super.key});

  static const routeName = 'tutor-wallet';
  static const routePath = '/tutor/wallet';

  @override
  ConsumerState<TutorWalletPage> createState() => _TutorWalletPageState();
}

class _TutorWalletPageState extends ConsumerState<TutorWalletPage> {
  int _selectedTabIndex = 0; // 0: Riwayat Saldo, 1: Pengajuan Penarikan

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);
    final payoutRequestsAsync = ref.watch(payoutRequestsProvider);

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
              
              // Segmented Tab Switcher
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _selectedTabIndex == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Riwayat Saldo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabIndex == 0 ? const Color(0xFF4B176E) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTabIndex = 1),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _selectedTabIndex == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Pengajuan Penarikan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabIndex == 1 ? const Color(0xFF4B176E) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_selectedTabIndex == 0) ...[
                // TRANSACTION HISTORY
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
                                    ? const Color(0xFF206A42)
                                    : const Color(0xFFA6334A),
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
              ] else ...[
                // PAYOUT REQUESTS LIST
                payoutRequestsAsync.when(
                  data: (requests) {
                    if (requests.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: AppEmptyState(
                            message: 'Belum ada pengajuan',
                            hint: 'Pengajuan penarikan dana Anda akan terdaftar di sini',
                            icon: FluentIcons.receipt_money_24_regular,
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final req = requests[index];
                          
                          Color statusBg;
                          Color statusBorder;
                          Color statusText;
                          String statusLabel;

                          switch (req.status) {
                            case PayoutStatus.approved:
                              statusBg = const Color(0xFFD1FAE5);
                              statusBorder = const Color(0xFF6EE7B7);
                              statusText = const Color(0xFF059669);
                              statusLabel = 'Disetujui';
                            case PayoutStatus.completed:
                              statusBg = const Color(0xFFDBEAFE);
                              statusBorder = const Color(0xFF93C5FD);
                              statusText = const Color(0xFF2563EB);
                              statusLabel = 'Selesai';
                            case PayoutStatus.rejected:
                              statusBg = const Color(0xFFFEE2E2);
                              statusBorder = const Color(0xFFFCA5A5);
                              statusText = const Color(0xFFDC2626);
                              statusLabel = 'Ditolak';
                            case PayoutStatus.pending:
                              statusBg = const Color(0xFFFEF3C7);
                              statusBorder = const Color(0xFFFBBF24);
                              statusText = const Color(0xFFD97706);
                              statusLabel = 'Pending';
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rp ${req.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF191622),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusBorder),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tujuan: ${req.bankName} • ${req.accountNumber}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Penerima: ${req.accountHolder}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Diajukan pada: ${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year} ${req.createdAt.hour.toString().padLeft(2, '0')}:${req.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                
                                // REJECTION REASON EXPANDED
                                if (req.status == PayoutStatus.rejected && req.rejectionReason != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(FluentIcons.dismiss_circle_24_regular, color: Color(0xFFDC2626), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Alasan Penolakan: "${req.rejectionReason}"',
                                            style: const TextStyle(
                                              color: Color(0xFFDC2626),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // SIMULATOR ACTIONS FOR PENDING STATUS
                                if (req.status == PayoutStatus.pending) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(FluentIcons.shield_keyhole_24_regular, color: Color(0xFF4B176E), size: 16),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '[SIMULASI]',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4B176E)),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () async {
                                            final messenger =
                                                ScaffoldMessenger.of(
                                                  this.context,
                                                );
                                            try {
                                              await ref
                                                  .read(walletControllerProvider)
                                                  .simulatePayoutAdminAction(
                                                    req.id,
                                                    'completed',
                                                  );
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Simulasi: Penarikan Dana berhasil diselesaikan!',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Simulasi gagal: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            foregroundColor: const Color(0xFF059669),
                                          ),
                                          child: const Text('Setujui (Complete)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () async {
                                            final messenger =
                                                ScaffoldMessenger.of(
                                                  this.context,
                                                );
                                            final reasonCtrl =
                                                TextEditingController(
                                                  text:
                                                      'Nomor rekening tidak terdaftar atau nama salah.',
                                                );
                                            final confirm =
                                                await showDialog<bool>(
                                                  context: this.context,
                                                  builder:
                                                      (dialogContext) =>
                                                          AlertDialog(
                                                            title: const Text(
                                                              'Simulasi Tolak Payout',
                                                            ),
                                                            content:
                                                                TextFormField(
                                                                  controller:
                                                                      reasonCtrl,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                        labelText:
                                                                            'Alasan Penolakan',
                                                                      ),
                                                                ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      dialogContext,
                                                                      false,
                                                                    ),
                                                                child: const Text(
                                                                  'Batal',
                                                                ),
                                                              ),
                                                              FilledButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      dialogContext,
                                                                      true,
                                                                    ),
                                                                child: const Text(
                                                                  'Tolak',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                );
                                            if (confirm != true) {
                                              reasonCtrl.dispose();
                                              return;
                                            }
                                            try {
                                              await ref
                                                  .read(walletControllerProvider)
                                                  .simulatePayoutAdminAction(
                                                    req.id,
                                                    'rejected',
                                                    reason:
                                                        reasonCtrl.text.trim(),
                                                  );
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Simulasi: Penarikan Dana ditolak!',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Simulasi gagal: $e',
                                                  ),
                                                ),
                                              );
                                            } finally {
                                              reasonCtrl.dispose();
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            foregroundColor: const Color(0xFFDC2626),
                                          ),
                                          child: const Text('Tolak (Reject)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                        childCount: requests.length,
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
                    child: Center(child: Text('Gagal memuat pengajuan: $err')),
                  ),
                ),
              ],
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
