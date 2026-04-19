import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  static const routeName = 'inbox';
  static const routePath = '/inbox';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxBookingsProvider);
    final currentUid = ref.watch(authStateProvider).value?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox Chat')),
      body: inboxAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('Belum ada booking untuk chat.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final latestMessage = ref.watch(
                latestMessageByBookingProvider(booking.id),
              );
              final unreadCount =
                  ref.watch(unreadByBookingProvider(booking.id)).valueOrNull ??
                  0;
              final counterpart = currentUid == booking.studentUid
                  ? booking.tutorName
                  : booking.studentName;

              return Card(
                child: ListTile(
                  onTap: () => context.pushNamed(
                    ChatPage.routeName,
                    pathParameters: {'bookingId': booking.id},
                  ),
                  title: Text(
                    counterpart.isEmpty ? 'Chat Booking' : counterpart,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mapel: ${booking.subject}'),
                      Text(
                        latestMessage == null
                            ? 'Belum ada pesan. Mulai chat sekarang.'
                            : latestMessage.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(label: Text(booking.status.label)),
                      if (unreadCount > 0)
                        CircleAvatar(
                          radius: 10,
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
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
                const Text('Gagal memuat inbox chat.'),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(inboxBookingsProvider),
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
}
