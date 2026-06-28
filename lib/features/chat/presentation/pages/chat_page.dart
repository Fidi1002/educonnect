import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
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

  List<dynamic> _buildPreprocessedList(List<ChatMessage> messages) {
    final result = <dynamic>[];
    if (messages.isEmpty) return result;

    final sorted = messages.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (int i = 0; i < sorted.length; i++) {
      result.add(sorted[i]);

      final currentMsg = sorted[i];
      final isLast = i == sorted.length - 1;

      if (isLast) {
        result.add(_formatDateHeader(currentMsg.createdAt));
      } else {
        final nextMsg = sorted[i + 1];
        if (!_isSameDay(currentMsg.createdAt, nextMsg.createdAt)) {
          result.add(_formatDateHeader(currentMsg.createdAt));
        }
      }
    }
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Hari Ini';
    } else if (date == yesterday) {
      return 'Kemarin';
    } else {
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    }
  }

  LinearGradient _getAvatarGradient(String name) {
    final code = name.isEmpty ? 0 : name.codeUnitAt(0);
    final colors = [
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      [const Color(0xFF3B82F6), const Color(0xFF10B981)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
    ];
    final index = code % colors.length;
    return LinearGradient(
      colors: colors[index],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));
    final messagesAsync = ref.watch(bookingMessagesProvider(widget.bookingId));
    final currentUid = ref.watch(authStateProvider).value?.uid ?? '';
    final isSending = ref.watch(chatSendingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF131926) : Colors.white,
            iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getAvatarGradient(title),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(title),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              booking.subject,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
                    
                    final items = _buildPreprocessedList(messages);

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is String) {
                          return _DateHeaderWidget(label: item);
                        } else if (item is ChatMessage) {
                          final mine = item.senderUid == currentUid;
                          return _MessageBubble(message: item, mine: mine);
                        }
                        return const SizedBox.shrink();
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
              
              // Pill Shape Input Panel
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: isDark ? null : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  minLines: 1,
                                  maxLines: 4,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Tulis pesan...',
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: IconButton(
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
                                          'Gagal mengirim pesan: ${error.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
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

class _DateHeaderWidget extends StatelessWidget {
  const _DateHeaderWidget({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
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
                color: const Color(0xFF7B2CBF).withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          )
        : BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          );

    final textColor = mine ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B));
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.body,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 9,
                        color: mine ? Colors.white70 : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 13,
                        color: message.isRead ? const Color(0xFF38BDF8) : Colors.white60,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
