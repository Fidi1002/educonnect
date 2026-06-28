import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/wallet/application/wallet_controller.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_transaction.dart';
import 'package:educonnect/features/wallet/domain/models/wallet_balance.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);
    final payoutRequestsAsync = ref.watch(payoutRequestsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dompet & Penghasilan'),
        actions: [
          balanceAsync.when(
            data: (balance) {
              final bool isWalletEmpty = balance.availableBalance == 0 &&
                  balance.pendingBalance == 0 &&
                  balance.totalEarned == 0;
              if (isWalletEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B176E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4B176E).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'SIMULASI',
                        style: TextStyle(
                          color: Color(0xFF4B176E),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: balanceAsync.when(
        data: (balance) {
          final bool isWalletEmpty = balance.availableBalance == 0 &&
              balance.pendingBalance == 0 &&
              balance.totalEarned == 0;

          final displayBalance = isWalletEmpty
              ? WalletBalance(
                  availableBalance: 750000.0,
                  pendingBalance: 150000.0,
                  totalEarned: 900000.0,
                )
              : balance;

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
                          'Rp ${displayBalance.availableBalance.toStringAsFixed(0)}',
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
                                    'Rp ${displayBalance.pendingBalance.toStringAsFixed(0)}',
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
                              onPressed: displayBalance.availableBalance > 0
                                  ? () => RequestPayoutSheet.show(
                                      context, displayBalance.availableBalance)
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
                      color: isDark ? const Color(0xFF131926) : const Color(0xFFF1F5F9),
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
                                color: _selectedTabIndex == 0
                                    ? (isDark ? const Color(0xFF1B2336) : Colors.white)
                                    : Colors.transparent,
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
                                  color: _selectedTabIndex == 0
                                      ? (isDark ? Colors.white : const Color(0xFF4B176E))
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                                color: _selectedTabIndex == 1
                                    ? (isDark ? const Color(0xFF1B2336) : Colors.white)
                                    : Colors.transparent,
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
                                  color: _selectedTabIndex == 1
                                      ? (isDark ? Colors.white : const Color(0xFF4B176E))
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                    final displayTxs = (isWalletEmpty && transactions.isEmpty)
                        ? [
                            WalletTransaction(
                              id: 'dummy-tx-1',
                              tutorUid: '',
                              amount: 450000.0,
                              type: TransactionType.credit,
                              description: 'Selesai Sesi Belajar #EDC-8712 (Budi Santoso)',
                              referenceType: 'booking',
                              referenceId: 'ref-1',
                              createdAt: DateTime.now().subtract(const Duration(days: 2)),
                            ),
                            WalletTransaction(
                              id: 'dummy-tx-2',
                              tutorUid: '',
                              amount: 300000.0,
                              type: TransactionType.credit,
                              description: 'Selesai Sesi Belajar #EDC-8541 (Siti Rahma)',
                              referenceType: 'booking',
                              referenceId: 'ref-2',
                              createdAt: DateTime.now().subtract(const Duration(days: 5)),
                            ),
                            WalletTransaction(
                              id: 'dummy-tx-3',
                              tutorUid: '',
                              amount: 150000.0,
                              type: TransactionType.debit,
                              description: 'Penarikan Dana ke Bank BCA (Sukses)',
                              referenceType: 'payout',
                              referenceId: 'ref-3',
                              createdAt: DateTime.now().subtract(const Duration(days: 10)),
                            ),
                          ]
                        : transactions;

                    if (displayTxs.isEmpty) {
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
                          final tx = displayTxs[index];
                          final isCredit = tx.type == TransactionType.credit;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B2336) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isCredit
                                        ? const Color(0xFFD1FAE5).withValues(alpha: isDark ? 0.15 : 0.6)
                                        : const Color(0xFFFEE2E2).withValues(alpha: isDark ? 0.15 : 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit
                                        ? FluentIcons.arrow_down_24_regular
                                        : FluentIcons.arrow_up_24_regular,
                                    color: isCredit
                                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: tx.referenceType == 'booking'
                                                  ? const Color(0xFF4B176E).withValues(alpha: 0.1)
                                                  : const Color(0xFFFF1377).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tx.referenceType == 'booking' ? 'PENDAPATAN LES' : 'PENARIKAN',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                color: tx.referenceType == 'booking'
                                                    ? const Color(0xFF4B176E)
                                                    : const Color(0xFFFF1377),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        tx.description.isEmpty
                                            ? (isCredit ? 'Penerimaan Dana' : 'Penarikan Dana')
                                            : tx.description,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${isCredit ? '+' : '-'} Rp ${tx.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isCredit
                                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: displayTxs.length,
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
                    final displayRequests = (isWalletEmpty && requests.isEmpty)
                        ? [
                            PayoutRequest(
                              id: 'dummy-payout-1',
                              tutorUid: '',
                              amount: 150000.0,
                              bankName: 'BCA',
                              accountNumber: '8701234567',
                              accountHolder: 'Tutor EduConnect',
                              status: PayoutStatus.pending,
                              createdAt: DateTime.now().subtract(const Duration(hours: 12)),
                            ),
                          ]
                        : requests;

                    if (displayRequests.isEmpty) {
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
                          final req = displayRequests[index];
                          
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
                              color: isDark ? const Color(0xFF1B2336) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF191622),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                const SizedBox(height: 12),
                                Divider(color: isDark ? const Color(0xFF28354E) : const Color(0xFFF1F5F9), height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.account_balance, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tujuan: ${req.bankName} • ${req.accountNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.person, color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Penerima: ${req.accountHolder}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Diajukan pada: ${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year} ${req.createdAt.hour.toString().padLeft(2, '0')}:${req.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                
                                // REJECTION REASON EXPANDED (PREMIUM REDESIGN)
                                if (req.status == PayoutStatus.rejected && req.rejectionReason != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 14),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.15 : 0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.25 : 0.15)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(FluentIcons.warning_24_filled, color: Color(0xFFDC2626), size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Penarikan Dana Ditolak Admin',
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Alasan Penolakan:',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '"${req.rejectionReason}"',
                                          style: TextStyle(
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(FluentIcons.info_16_regular, color: Color(0xFF64748B), size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Saran: Harap periksa kembali nomor rekening dan nama pemilik bank Anda sebelum mengajukan penarikan baru.',
                                                style: TextStyle(
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                        childCount: displayRequests.length,
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
