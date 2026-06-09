import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
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
            body: AppEmptyState(
              message: 'Chat tidak dapat dibuka.',
              hint: 'Booking terkait tidak ditemukan atau sudah tidak tersedia.',
              icon: Icons.forum_outlined,
              fullScreen: false,
            ),
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
                      return const AppEmptyState(
                        message: 'Belum ada pesan.',
                        hint: 'Mulai percakapan dengan mengirim pesan pertama.',
                        icon: Icons.mark_chat_unread_outlined,
                        fullScreen: false,
                      );
                    }
                    Future<void>.microtask(() {
                      ref
                          .read(chatControllerProvider)
                          .markAsRead(widget.bookingId);
                    });
                    final sorted = messages.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final item = sorted[index];
                        final mine = item.senderUid == currentUid;
                        return _MessageBubble(message: item, mine: mine);
                      },
                    );
                  },
                  loading: () => const AppLoadingState(
                    message: 'Memuat percakapan...',
                    fullScreen: false,
                  ),
                  error: (error, _) => AppErrorState(
                    message: 'Gagal memuat percakapan.',
                    detail: error.toString(),
                    onRetry: () =>
                        ref.invalidate(bookingMessagesProvider(widget.bookingId)),
                    fullScreen: false,
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
                                        'Gagal mengirim pesan. Coba lagi sebentar lagi. ${error.toString()}',
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
      loading: () => const Scaffold(
        body: AppLoadingState(message: 'Memuat chat...', fullScreen: false),
      ),
      error: (error, _) => Scaffold(
        body: AppErrorState(
          message: 'Gagal memuat data chat.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(bookingByIdProvider(widget.bookingId)),
          fullScreen: false,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    final bubbleDecoration = mine
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          )
        : BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF1F5F9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isDark ? colorScheme.outline.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
            ),
          );

    final textColor = mine ? Colors.white : colorScheme.onSurface;
    final timeText = '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: bubbleDecoration,
            child: Text(
              message.body,
              style: TextStyle(
                color: textColor,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 3,
              bottom: 5,
              left: mine ? 0 : 8,
              right: mine ? 8 : 0,
            ),
            child: Text(
              timeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
