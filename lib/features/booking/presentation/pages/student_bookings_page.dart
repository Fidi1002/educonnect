import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentBookingsPage extends ConsumerStatefulWidget {
  const StudentBookingsPage({super.key});

  static const routeName = 'student-bookings';
  static const routePath = '/student/bookings';

  @override
  ConsumerState<StudentBookingsPage> createState() =>
      _StudentBookingsPageState();
}

class _StudentBookingsPageState extends ConsumerState<StudentBookingsPage> {
  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myStudentBookingsProvider);
    final isLoading = ref.watch(bookingLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Booking Saya')),
      body: bookingsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState(message: 'Belum ada booking kelas.');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _BookingCard(
                item: item,
                showTutorName: true,
                paymentLoading: isLoading,
                onPayDummy: item.status == BookingStatus.awaitingPayment
                    ? () => _payDummy(item.id)
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RetryState(
          message: 'Gagal memuat booking.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myStudentBookingsProvider),
        ),
      ),
    );
  }

  Future<void> _payDummy(String bookingId) async {
    try {
      await ref
          .read(bookingControllerProvider)
          .payDummyBooking(bookingId: bookingId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran dummy berhasil. Status: Lunas.'),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran gagal: ${error.toString()}')),
      );
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.item,
    required this.paymentLoading,
    this.showTutorName = false,
    this.onPayDummy,
  });

  final BookingItem item;
  final bool showTutorName;
  final bool paymentLoading;
  final VoidCallback? onPayDummy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.subject,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(label: Text(item.status.label)),
              ],
            ),
            if (showTutorName)
              Text(
                'Tutor: ${item.tutorName.isEmpty ? item.tutorUid : item.tutorName}',
              ),
            Text(
              'Jadwal: ${item.sessionStart.day}/${item.sessionStart.month}/${item.sessionStart.year} '
              '${item.sessionStart.hour.toString().padLeft(2, '0')}:${item.sessionStart.minute.toString().padLeft(2, '0')}',
            ),
            Text('Durasi: ${item.durationMinutes} menit'),
            Text('Biaya: Rp ${item.totalAmount}'),
            if (item.paidAt != null)
              Text(
                'Dibayar: ${item.paidAt!.day}/${item.paidAt!.month}/${item.paidAt!.year} '
                '${item.paidAt!.hour.toString().padLeft(2, '0')}:${item.paidAt!.minute.toString().padLeft(2, '0')}',
              ),
            if (item.message.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Catatan: ${item.message}'),
            ],
            if (onPayDummy != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: paymentLoading ? null : onPayDummy,
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(
                        paymentLoading
                            ? 'Memproses...'
                            : 'Bayar Sekarang (Dummy)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.pushNamed(
                        ChatPage.routeName,
                        pathParameters: {'bookingId': item.id},
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  ChatPage.routeName,
                  pathParameters: {'bookingId': item.id},
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Buka Chat'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
