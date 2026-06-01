import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/student_transaction.dart';
import 'package:educonnect/features/booking/presentation/utils/invoice_pdf_generator.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StudentTransactionHistoryPage extends ConsumerStatefulWidget {
  const StudentTransactionHistoryPage({super.key});

  static const routeName = 'student-transactions';
  static const routePath = '/student/transactions';

  @override
  ConsumerState<StudentTransactionHistoryPage> createState() =>
      _StudentTransactionHistoryPageState();
}

class _StudentTransactionHistoryPageState
    extends ConsumerState<StudentTransactionHistoryPage> {
  final Map<String, bool> _pdfLoadingState = {};

  Future<void> _downloadInvoice(StudentTransaction tx) async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final studentName = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName
        : 'Murid EduConnect';

    setState(() {
      _pdfLoadingState[tx.id] = true;
    });

    try {
      await InvoicePdfGenerator.generateAndShareInvoice(tx, studentName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh invoice: ${e.toString()}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pdfLoadingState[tx.id] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(studentTransactionsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF4B176E),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentTransactionsProvider);
        },
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.payment_24_regular,
                      size: 64,
                      color: Color(0xFFA0AEC0),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Semua riwayat tagihan dan invoice les Anda akan muncul di sini.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  'Riwayat Pembayaran',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF4B176E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                ...transactions.map((tx) {
                  final isPaid = tx.paymentStatus == 'paid';
                  final isPending = tx.paymentStatus == 'pending';
                  final isRefunded = tx.paymentStatus == 'refunded';
                  final isPdfLoading = _pdfLoadingState[tx.id] ?? false;

                  // Color coding for status
                  final statusColor = isPaid
                      ? const Color(0xFF10B981)
                      : isPending
                          ? const Color(0xFFF59E0B)
                          : isRefunded
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFEF4444);

                  final statusLabel = isPaid
                      ? 'Lunas'
                      : isPending
                          ? 'Menunggu Pembayaran'
                          : isRefunded
                              ? 'Refunded'
                              : 'Gagal';

                  final statusBgColor = statusColor.withValues(alpha: 0.1);

                  final dateText = tx.paidAt != null
                      ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.paidAt!)
                      : tx.dueAt != null
                          ? 'Jatuh Tempo: ${DateFormat('dd MMM yyyy', 'id_ID').format(tx.dueAt!)}'
                          : '-';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              Text(
                                'Cycle #${tx.cycleNumber}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Les ${tx.subject}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tutor: ${tx.tutorName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFEDF2F7)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currencyFormat.format(tx.amount),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF4B176E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                ],
                              ),
                              if (isPaid)
                                ElevatedButton.icon(
                                  onPressed: isPdfLoading ? null : () => _downloadInvoice(tx),
                                  icon: isPdfLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF4B176E),
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          FluentIcons.arrow_download_24_regular,
                                          size: 18,
                                        ),
                                  label: const Text('Invoice'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4B176E),
                                    backgroundColor: const Color(0xFFF3F0F7),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () =>
              const AppLoadingState(message: 'Memuat riwayat pembayaran...'),
          error: (error, _) => AppErrorState(
            message: 'Gagal memuat riwayat pembayaran.',
            detail: error.toString(),
            onRetry: () => ref.invalidate(studentTransactionsProvider),
            fullScreen: true,
          ),
        ),
      ),
    );
  }
}
