import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
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
            return const AppEmptyState(
              message: 'Belum ada percakapan aktif.',
              hint: 'Chat akan muncul setelah kamu memiliki booking dengan tutor.',
              icon: FluentIcons.chat_24_regular,
              fullScreen: true,
            );
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
                            ? 'Belum ada pesan. Mulai percakapan sekarang.'
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
        loading: () => const AppLoadingState(message: 'Memuat inbox chat...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat inbox chat.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(inboxBookingsProvider),
          fullScreen: true,
        ),
      ),
    );
  }
}
