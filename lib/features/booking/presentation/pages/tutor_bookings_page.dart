import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorBookingsPage extends ConsumerStatefulWidget {
  const TutorBookingsPage({super.key});

  static const routeName = 'tutor-bookings';
  static const routePath = '/tutor/bookings';

  @override
  ConsumerState<TutorBookingsPage> createState() => _TutorBookingsPageState();
}

class _TutorBookingsPageState extends ConsumerState<TutorBookingsPage> {
  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myTutorBookingsProvider);
    final isLoading = ref.watch(bookingLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Booking Murid')),
      body: bookingsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada booking dari murid.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Chip(label: Text(item.status.label)),
                        ],
                      ),
                      Text(
                        'Murid: ${item.studentName.isEmpty ? item.studentUid : item.studentName}',
                      ),
                      Text(
                        'Jadwal: ${item.sessionStart.day}/${item.sessionStart.month}/${item.sessionStart.year} '
                        '${item.sessionStart.hour.toString().padLeft(2, '0')}:${item.sessionStart.minute.toString().padLeft(2, '0')}',
                      ),
                      Text('Durasi: ${item.durationMinutes} menit'),
                      Text('Biaya: Rp ${item.totalAmount}'),
                      if (item.message.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Catatan: ${item.message}'),
                      ],
                      if (item.status == BookingStatus.pending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _handleRespond(
                                        bookingId: item.id,
                                        status: BookingStatus.rejected,
                                        successMessage: 'Booking ditolak.',
                                      ),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _handleRespond(
                                        bookingId: item.id,
                                        status: BookingStatus.awaitingPayment,
                                        successMessage:
                                            'Booking diterima. Menunggu pembayaran murid.',
                                      ),
                                child: const Text('Terima'),
                              ),
                            ),
                          ],
                        ),
                      ] else if (item.status == BookingStatus.paid) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _handleRespond(
                                        bookingId: item.id,
                                        status: BookingStatus.completed,
                                        successMessage:
                                            'Kelas ditandai selesai.',
                                      ),
                                child: const Text('Tandai Selesai'),
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
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(height: 8),
                const Text('Gagal memuat booking tutor.'),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(myTutorBookingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRespond({
    required String bookingId,
    required BookingStatus status,
    required String successMessage,
  }) async {
    try {
      await ref
          .read(bookingControllerProvider)
          .respondBooking(bookingId: bookingId, status: status);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aksi booking gagal: ${error.toString()}')),
      );
    }
  }
}
