import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/domain/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.bookingId, super.key});

  static const routeName = 'chat';
  static const routePath = '/chat/:bookingId';

  final String bookingId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(chatControllerProvider).markAsRead(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));
    final messagesAsync = ref.watch(bookingMessagesProvider(widget.bookingId));
    final currentUid = ref.watch(authStateProvider).value?.uid ?? '';
    final isSending = ref.watch(chatSendingProvider);

    return bookingAsync.when(
      data: (booking) {
        if (booking == null) {
          return const Scaffold(
            body: Center(child: Text('Booking tidak ditemukan.')),
          );
        }

        final title = currentUid == booking.studentUid
            ? (booking.tutorName.isEmpty ? 'Tutor' : booking.tutorName)
            : (booking.studentName.isEmpty ? 'Murid' : booking.studentName);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                Text(
                  'Status: ${booking.status.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Belum ada pesan. Mulai chat sekarang.'),
                      );
                    }
                    Future<void>.microtask(() {
                      ref
                          .read(chatControllerProvider)
                          .markAsRead(widget.bookingId);
                    });
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final item = messages[messages.length - 1 - index];
                        final mine = item.senderUid == currentUid;
                        return _MessageBubble(message: item, mine: mine);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat chat: $error'),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Tulis pesan...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: isSending
                            ? null
                            : () async {
                                final body = _messageController.text.trim();
                                if (body.isEmpty) {
                                  return;
                                }
                                try {
                                  await ref
                                      .read(chatControllerProvider)
                                      .sendMessage(
                                        booking: booking,
                                        body: body,
                                      );
                                  _messageController.clear();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  await ref
                                      .read(chatControllerProvider)
                                      .markAsRead(widget.bookingId);
                                } on Exception catch (error) {
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal kirim pesan: ${error.toString()}',
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Gagal memuat booking chat: $error')),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = mine
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(message.body),
        ),
      ],
    );
  }
}
