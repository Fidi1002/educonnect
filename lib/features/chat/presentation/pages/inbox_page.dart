import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  static const routeName = 'inbox';
  static const routePath = '/inbox';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxBookingsProvider);
    final currentUid = ref.watch(authStateProvider).value?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Pesan Masuk',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -0.8,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: inboxAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const AppEmptyState(
              message: 'Belum ada percakapan aktif.',
              hint: 'Pesan akan muncul setelah Anda memesan jadwal dengan tutor pilihan.',
              icon: FluentIcons.chat_24_regular,
              fullScreen: true,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: bookings.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
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

              return Semantics(
                label: 'Percakapan dengan ${counterpart.isEmpty ? 'Chat Booking' : counterpart}. Mata pelajaran ${booking.subject}. ${unreadCount > 0 ? '$unreadCount pesan belum dibaca' : ''}',
                button: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: unreadCount > 0
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outline.withValues(alpha: 0.15),
                      width: unreadCount > 0 ? 1.5 : 1,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: unreadCount > 0
                                  ? colorScheme.primary.withValues(alpha: 0.08)
                                  : colorScheme.outline.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.pushNamed(
                        ChatPage.routeName,
                        pathParameters: {'bookingId': booking.id},
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Dynamic Gradient Avatar
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _getAvatarGradient(counterpart),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getInitials(counterpart),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Chat Content Information
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          counterpart.isEmpty ? 'Chat Booking' : counterpart,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusBadge(context, booking.status),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    booking.subject,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    latestMessage == null
                                        ? 'Belum ada pesan. Mulai obrolan sekarang.'
                                        : latestMessage.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                                      color: unreadCount > 0
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Badge & Timing Accents
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (latestMessage != null)
                                  Text(
                                    _formatTime(latestMessage.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                                      color: unreadCount > 0
                                          ? colorScheme.primary
                                          : colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
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
                )
                .animate()
                .fadeIn(delay: (index * 60).ms, duration: 300.ms)
                .slideY(begin: 0.1, curve: Curves.easeOutQuad),
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

  // Generates beautifully tailored gradients based on name characters
  LinearGradient _getAvatarGradient(String name) {
    final code = name.isEmpty ? 0 : name.codeUnitAt(0);
    final colors = [
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)], // Violet to Pink
      [const Color(0xFF3B82F6), const Color(0xFF10B981)], // Blue to Emerald
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // Amber to Red
      [const Color(0xFFEC4899), const Color(0xFFF43F5E)], // Pink to Rose
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo to Violet
    ];
    final index = code % colors.length;
    return LinearGradient(
      colors: colors[index],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Generates initials from counterpart name
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // Formats relative time representation
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (target == today) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (target == yesterday) {
      return 'Kemarin';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  // Generates refined tags compatible with M3 dynamic theme scheme
  Widget _buildStatusBadge(BuildContext context, BookingStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (status) {
      case BookingStatus.paid:
        bg = colorScheme.secondaryContainer;
        fg = colorScheme.onSecondaryContainer;
        break;
      case BookingStatus.awaitingPayment:
        bg = colorScheme.tertiaryContainer;
        fg = colorScheme.onTertiaryContainer;
        break;
      case BookingStatus.pending:
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        break;
      default:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
