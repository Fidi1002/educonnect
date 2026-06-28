import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/notifications/application/notification_controller.dart';
import 'package:educonnect/features/notifications/domain/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';


class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  static const routeName = 'notifications';
  static const routePath = '/notifications';

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -0.8,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          if (unreadCount > 0)
            Semantics(
              label: 'Tombol tandai semua notifikasi sebagai dibaca',
              button: true,
              child: TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(notificationControllerProvider).markAllAsRead();
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Semua notifikasi telah ditandai dibaca.'),
                      backgroundColor: colorScheme.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(FluentIcons.checkmark_circle_24_regular, size: 18),
                label: const Text(
                  'Semua Dibaca',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Belum ada notifikasi.',
              hint: 'Informasi pemesanan kelas, sesi belajar, dan pesan masuk akan muncul di sini.',
              icon: FluentIcons.alert_24_regular,
              fullScreen: true,
            );
          }
          final sections = _groupByDay(items);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Staggered calendar section header with vertical accent bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          section.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...section.items.asMap().entries.map((entry) {
                    final itemIndex = entry.key;
                    final item = entry.value;
                    final customStyle = _getNotificationStyle(item, colorScheme);

                    return Semantics(
                      label: 'Notifikasi: ${item.title}. ${item.body}. Dikirim ${item.isRead ? 'telah dibaca' : 'belum dibaca'}',
                      button: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? Theme.of(context).cardTheme.color
                                : colorScheme.primaryContainer.withValues(alpha: isDark ? 0.08 : 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: item.isRead
                                  ? colorScheme.outline.withValues(alpha: 0.1)
                                  : colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _onNotificationTap(context, item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Custom rounded icon container with pastel background
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: customStyle.backgroundColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        customStyle.iconData,
                                        color: customStyle.foregroundColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Notification detail text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w900,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.body,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.35,
                                              color: colorScheme.onSurface.withValues(
                                                alpha: item.isRead ? 0.5 : 0.75,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Timestamp and unread status pill
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatTimeOnly(item.createdAt),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                                            color: item.isRead
                                                ? colorScheme.onSurface.withValues(alpha: 0.35)
                                                : colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: colorScheme.tertiary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.tertiary.withValues(alpha: 0.5),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                )
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: ((index * 100) + (itemIndex * 40)).ms, duration: 300.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOutQuad),
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const AppLoadingState(message: 'Memuat notifikasi...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat notifikasi.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myNotificationsProvider),
          fullScreen: true,
        ),
      ),
    );
  }

  String _formatDateLong(DateTime dateTime) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  Future<void> _onNotificationTap(
    BuildContext context,
    AppNotification item,
  ) async {
    final controller = ref.read(notificationControllerProvider);
    if (!item.isRead) {
      await controller.markAsRead(item.id);
    }

    if (!context.mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    final customStyle = _getNotificationStyle(item, colorScheme);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: CircleAvatar(
            radius: 28,
            backgroundColor: customStyle.backgroundColor,
            child: Icon(
              customStyle.iconData,
              color: customStyle.foregroundColor,
              size: 28,
            ),
          ),
          title: Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Diterima: ${_formatDateLong(item.createdAt)} • ${_formatTimeOnly(item.createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (item.targetType == 'booking_session' && item.targetId.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  
                  try {
                    final session = await ref
                        .read(bookingControllerProvider)
                        .fetchSessionById(item.targetId);
                    
                    if (session == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Detail sesi tidak ditemukan.')),
                      );
                      return;
                    }
                    
                    final currentUid = ref.read(authStateProvider).value?.uid;
                    
                    if (currentUid == session.tutorUid) {
                      router.pushNamed(
                        TutorBookingsPage.routeName,
                        queryParameters: {
                          'bookingId': session.bookingId,
                          'sessionId': session.id,
                        },
                      );
                    } else if (currentUid == session.studentUid) {
                      router.pushNamed(
                        StudentBookingsPage.routeName,
                        queryParameters: {
                          'bookingId': session.bookingId,
                          'sessionId': session.id,
                        },
                      );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Gagal memuat detail sesi: $e')),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Lihat Sesi',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green),
                ),
              ),
          ],
        );
      },
    );
  }

  // Helper formatting for message dispatch clock hours
  String _formatTimeOnly(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Contextual Rich Icon styling configurations
  _NotificationStyle _getNotificationStyle(AppNotification item, ColorScheme colors) {
    final bool isChat = item.category == 'chat' || item.targetType == 'booking_chat';
    final bool isSession = item.targetType == 'booking_session' || item.targetType == 'session_change';
    final bool isBooking = item.category == 'booking';

    if (isChat) {
      return _NotificationStyle(
        iconData: FluentIcons.chat_24_regular,
        foregroundColor: const Color(0xFF6366F1), // Indigo
        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
      );
    } else if (isSession) {
      return _NotificationStyle(
        iconData: FluentIcons.clock_24_regular,
        foregroundColor: const Color(0xFFF59E0B), // Amber
        backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
      );
    } else if (isBooking) {
      return _NotificationStyle(
        iconData: FluentIcons.calendar_ltr_24_regular,
        foregroundColor: const Color(0xFF10B981), // Emerald
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
      );
    }

    return _NotificationStyle(
      iconData: FluentIcons.alert_24_regular,
      foregroundColor: const Color(0xFFEF4444), // Rose Red
      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
    );
  }

  List<_NotificationDaySection> _groupByDay(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final buckets = <DateTime, List<AppNotification>>{};

    for (final item in items) {
      final date = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      buckets.putIfAbsent(date, () => <AppNotification>[]).add(item);
    }

    final sortedDays = buckets.keys.toList(growable: false)
      ..sort((a, b) => b.compareTo(a));

    return sortedDays
        .map((date) {
          String label;
          if (date == today) {
            label = 'Hari ini';
          } else if (date == yesterday) {
            label = 'Kemarin';
          } else {
            label = '${date.day}/${date.month}/${date.year}';
          }
          return _NotificationDaySection(
            label: label,
            items: buckets[date] ?? const [],
          );
        })
        .toList(growable: false);
  }
}

class _NotificationDaySection {
  const _NotificationDaySection({required this.label, required this.items});

  final String label;
  final List<AppNotification> items;
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.iconData,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData iconData;
  final Color foregroundColor;
  final Color backgroundColor;
}
