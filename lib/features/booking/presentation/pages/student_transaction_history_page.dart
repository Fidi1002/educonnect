import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/student_transaction.dart';
import 'package:educonnect/features/booking/presentation/utils/invoice_pdf_generator.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showTransactionDetailSheet(BuildContext context, StudentTransaction tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isPaid = tx.paymentStatus == 'paid';
    final isPending = tx.paymentStatus == 'pending';
    final isRefunded = tx.paymentStatus == 'refunded';

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

    final paidDateText = tx.paidAt != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(tx.paidAt!)
        : '-';

    final dueDateText = tx.dueAt != null
        ? DateFormat('dd MMMM yyyy', 'id_ID').format(tx.dueAt!)
        : '-';

    final createdDateText = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(tx.createdAt);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131926) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF4B176E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Les ${tx.subject} (Cycle #${tx.cycleNumber})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : const Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(tx.amount),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Divider(height: 1, color: isDark ? const Color(0xFF28354E) : const Color(0xFFEDF2F7)),
              const SizedBox(height: 20),
              
              _buildDetailRow(
                context,
                label: 'Nama Tutor',
                value: tx.tutorName,
                isDark: isDark,
              ),
              _buildDetailRow(
                context,
                label: 'Metode Pembayaran',
                value: tx.paymentMethod.toUpperCase(),
                isDark: isDark,
              ),
              _buildDetailRow(
                context,
                label: 'ID Transaksi',
                value: tx.id,
                isDark: isDark,
                showCopy: true,
              ),
              _buildDetailRow(
                context,
                label: 'No. Referensi',
                value: tx.paymentRef.isNotEmpty ? tx.paymentRef : '-',
                isDark: isDark,
              ),
              _buildDetailRow(
                context,
                label: 'Waktu Dibuat',
                value: createdDateText,
                isDark: isDark,
              ),
              if (tx.paidAt != null)
                _buildDetailRow(
                  context,
                  label: 'Waktu Pembayaran',
                  value: paidDateText,
                  isDark: isDark,
                ),
              if (tx.dueAt != null && !isPaid)
                _buildDetailRow(
                  context,
                  label: 'Jatuh Tempo',
                  value: dueDateText,
                  isDark: isDark,
                ),

              const SizedBox(height: 32),
              if (isPaid)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadInvoice(tx);
                    },
                    icon: const Icon(FluentIcons.arrow_download_24_regular),
                    label: const Text(
                      'Unduh Invoice PDF',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4B176E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
    bool showCopy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF718096),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A202C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showCopy && value != '-') ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID Transaksi disalin ke papan klip.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(
                      FluentIcons.copy_24_regular,
                      size: 14,
                      color: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(studentTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Riwayat Pembayaran',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF4B176E),
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF4B176E),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentTransactionsProvider);
        },
        child: transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.payment_24_regular,
                      size: 64,
                      color: isDark ? Colors.white30 : const Color(0xFFA0AEC0),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semua riwayat tagihan dan invoice les Anda akan muncul di sini.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : const Color(0xFF718096),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                ...transactions.map((tx) {
                  final isPaid = tx.paymentStatus == 'paid';
                  final isPending = tx.paymentStatus == 'pending';
                  final isRefunded = tx.paymentStatus == 'refunded';
                  final isPdfLoading = _pdfLoadingState[tx.id] ?? false;

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
                    color: isDark ? const Color(0xFF1B2336) : Colors.white,
                    child: InkWell(
                      onTap: () => _showTransactionDetailSheet(context, tx),
                      borderRadius: BorderRadius.circular(20),
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
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white54 : const Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Les ${tx.subject}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tutor: ${tx.tutorName}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF28354E) : const Color(0xFFEDF2F7),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currencyFormat.format(tx.amount),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : const Color(0xFF718096),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isPaid)
                                  ElevatedButton.icon(
                                    onPressed: isPdfLoading ? null : () => _downloadInvoice(tx),
                                    icon: isPdfLoading
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                isDark ? Colors.white : const Color(0xFF4B176E),
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            FluentIcons.arrow_download_24_regular,
                                            size: 18,
                                          ),
                                    label: const Text('Invoice'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF4B176E),
                                      backgroundColor: isDark ? const Color(0xFF28354E) : const Color(0xFFF3F0F7),
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
