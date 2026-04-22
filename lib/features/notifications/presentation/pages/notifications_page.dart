import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/notifications/application/notification_controller.dart';
import 'package:educonnect/features/notifications/domain/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  static const routeName = 'notifications';
  static const routePath = '/notifications';

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  var _autoMarkInProgress = false;
  ProviderSubscription<AsyncValue<List<AppNotification>>>? _notificationsSub;

  @override
  void initState() {
    super.initState();
    _notificationsSub = ref.listenManual(myNotificationsProvider, (
      previous,
      next,
    ) {
      final items = next.valueOrNull ?? const <AppNotification>[];
      final hasUnread = items.any((item) => !item.isRead);
      if (!hasUnread || _autoMarkInProgress) {
        return;
      }
      _autoMarkInProgress = true;
      Future<void>(() async {
        try {
          await ref.read(notificationControllerProvider).markAllAsRead();
        } finally {
          _autoMarkInProgress = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationsSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(myNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada notifikasi.'));
          }
          final sections = _groupByDay(items);
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index > 0) const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Text(
                      section.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...section.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          onTap: () => _onNotificationTap(context, item),
                          leading: Icon(
                            item.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: item.isRead
                                ? Colors.black45
                                : const Color(0xFF4B176E),
                          ),
                          title: Text(item.title),
                          subtitle: Text(item.body),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Gagal memuat notifikasi: $error')),
      ),
    );
  }

  Future<void> _onNotificationTap(
    BuildContext context,
    AppNotification item,
  ) async {
    final controller = ref.read(notificationControllerProvider);
    if (!item.isRead) {
      await controller.markAsRead(item.id);
    }

    final role = ref.read(currentUserProfileProvider).value?.role;
    if (role == null || role == AppUserRole.unknown) {
      return;
    }

    final bookingId = await controller.resolveBookingIdFromTarget(
      targetType: item.targetType,
      targetId: item.targetId,
    );
    final query = <String, String>{};
    if (bookingId != null && bookingId.isNotEmpty) {
      query['bookingId'] = bookingId;
    }
    final isSessionTarget =
        item.targetType == 'booking_session' ||
        item.targetType == 'session_change';
    if (isSessionTarget && item.targetId.isNotEmpty) {
      query['sessionId'] = item.targetId;
    }

    if (!context.mounted) {
      return;
    }

    if (role == AppUserRole.student) {
      context.pushNamed(StudentBookingsPage.routeName, queryParameters: query);
      return;
    }

    if (role == AppUserRole.tutor) {
      context.pushNamed(TutorBookingsPage.routeName, queryParameters: query);
    }
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
