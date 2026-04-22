import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/availability/presentation/pages/tutor_availability_page.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_study_calendar_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_students_page.dart';
import 'package:educonnect/features/notifications/application/notification_controller.dart';
import 'package:educonnect/features/notifications/presentation/pages/notifications_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorHomePage extends ConsumerWidget {
  const TutorHomePage({super.key});

  static const routeName = 'tutor-home';
  static const routePath = '/tutor/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final sessionsAsync = ref.watch(myTutorSessionsProvider);
    final bookingsAsync = ref.watch(myTutorBookingsProvider);
    final pendingCount = ref.watch(
      tutorPendingBookingsProvider.select(
        (value) => value.valueOrNull?.length ?? 0,
      ),
    );
    final unreadChatCount =
        ref.watch(unreadMessagesCountProvider).valueOrNull ?? 0;
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final waitingPaymentCount = ref.watch(tutorAwaitingPaymentCountProvider);
    return profileAsync.when(
      data: (profile) => _TutorHomeScaffold(
        profile: profile,
        pendingCount: pendingCount,
        waitingPaymentCount: waitingPaymentCount,
        unreadChatCount: unreadChatCount,
        unreadNotifications: unreadNotifications,
        sessionsAsync: sessionsAsync,
        bookingsAsync: bookingsAsync,
        onLogout: () => ref.read(authControllerProvider).signOut(),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _TutorHomeScaffold(
        profile: null,
        pendingCount: pendingCount,
        waitingPaymentCount: waitingPaymentCount,
        unreadChatCount: unreadChatCount,
        unreadNotifications: unreadNotifications,
        sessionsAsync: sessionsAsync,
        bookingsAsync: bookingsAsync,
        onLogout: () => ref.read(authControllerProvider).signOut(),
        profileError:
            'Realtime terputus sementara. Data profil akan dicoba ulang otomatis.',
      ),
    );
  }
}

class _TutorHomeScaffold extends StatelessWidget {
  const _TutorHomeScaffold({
    required this.profile,
    required this.pendingCount,
    required this.waitingPaymentCount,
    required this.unreadChatCount,
    required this.unreadNotifications,
    required this.sessionsAsync,
    required this.bookingsAsync,
    required this.onLogout,
    this.profileError,
  });

  final AppUserProfile? profile;
  final int pendingCount;
  final int waitingPaymentCount;
  final int unreadChatCount;
  final int unreadNotifications;
  final AsyncValue<List<BookingSession>> sessionsAsync;
  final AsyncValue<List<BookingItem>> bookingsAsync;
  final Future<void> Function() onLogout;
  final String? profileError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tutorName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Tutor';
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Tutor - $tutorName'),
        actions: [
          _ChatBadgeButton(
            count: unreadNotifications,
            onTap: () => context.pushNamed(NotificationsPage.routeName),
            icon: Icons.notifications_none,
          ),
          _ChatBadgeButton(
            count: unreadChatCount,
            onTap: () => context.pushNamed(InboxPage.routeName),
          ),
          IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profileError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profileError!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Ringkasan Hari Ini',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _TodaySessionsCard(
            sessionsAsync: sessionsAsync,
            bookingsAsync: bookingsAsync,
            onOpenCalendar: () =>
                context.pushNamed(TutorStudyCalendarPage.routeName),
            onOpenSession: (bookingId, sessionId) => context.pushNamed(
              TutorBookingsPage.routeName,
              queryParameters: {'bookingId': bookingId, 'sessionId': sessionId},
            ),
            now: now,
          ),
          const SizedBox(height: 10),
          _StatCard(
            title: 'Permintaan Kelas Baru',
            value: pendingCount.toString(),
            icon: Icons.notifications_active_outlined,
            color: colorScheme.primaryContainer,
          ),
          const SizedBox(height: 10),
          _StatCard(
            title: 'Menunggu Pembayaran',
            value: waitingPaymentCount.toString(),
            icon: Icons.payments_outlined,
            color: colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 10),
          _StatCard(
            title: 'Rating Tutor',
            value: '5.0',
            icon: Icons.star_outline,
            color: colorScheme.tertiaryContainer,
          ),
          const SizedBox(height: 20),
          Text(
            'Aksi Cepat',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => context.pushNamed(TutorProfileFormPage.routeName),
            icon: const Icon(Icons.edit_note),
            label: const Text('Lengkapi Profil Tutor'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(TutorBookingsPage.routeName),
            icon: const Icon(Icons.schedule_send),
            label: const Text('Kelola Booking Murid'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(TutorStudentsPage.routeName),
            icon: const Icon(Icons.people_outline),
            label: const Text('Murid Aktif'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(TutorAvailabilityPage.routeName),
            icon: const Icon(Icons.access_time_outlined),
            label: const Text('Atur Jadwal Ketersediaan'),
          ),
        ],
      ),
    );
  }
}

class _ChatBadgeButton extends StatelessWidget {
  const _ChatBadgeButton({
    required this.count,
    required this.onTap,
    this.icon = Icons.chat_bubble_outline,
  });

  final int count;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon)),
        if (count > 0)
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TodaySessionsCard extends StatelessWidget {
  const _TodaySessionsCard({
    required this.sessionsAsync,
    required this.bookingsAsync,
    required this.onOpenCalendar,
    required this.onOpenSession,
    required this.now,
  });

  final AsyncValue<List<BookingSession>> sessionsAsync;
  final AsyncValue<List<BookingItem>> bookingsAsync;
  final VoidCallback onOpenCalendar;
  final void Function(String bookingId, String sessionId) onOpenSession;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sesi Hari Ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenCalendar,
                  child: const Text('Kalender'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            sessionsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Gagal memuat sesi: $error'),
              data: (sessions) {
                final bookings = bookingsAsync.valueOrNull ?? const [];
                final bookingMap = <String, BookingItem>{
                  for (final booking in bookings) booking.id: booking,
                };

                final today = DateTime(now.year, now.month, now.day);
                final tomorrow = today.add(const Duration(days: 1));
                final todays =
                    sessions
                        .where(
                          (session) =>
                              session.sessionStart.isAfter(today) &&
                              session.sessionStart.isBefore(tomorrow),
                        )
                        .toList()
                      ..sort(
                        (a, b) => a.sessionStart.compareTo(b.sessionStart),
                      );

                if (todays.isEmpty) {
                  return const Text('Tidak ada sesi mengajar hari ini.');
                }

                final shortlist = todays.take(3).toList(growable: false);
                return Column(
                  children: [
                    ...shortlist.map((session) {
                      final booking = bookingMap[session.bookingId];
                      final subject = booking?.subject ?? 'Sesi Mengajar';
                      final studentName = booking?.studentName ?? 'Murid';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.school_outlined),
                        title: Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${session.sessionStart.hour.toString().padLeft(2, '0')}:${session.sessionStart.minute.toString().padLeft(2, '0')}'
                          ' - ${session.sessionEnd.hour.toString().padLeft(2, '0')}:${session.sessionEnd.minute.toString().padLeft(2, '0')}'
                          ' • $studentName',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            onOpenSession(session.bookingId, session.id),
                      );
                    }),
                    if (todays.length > 3)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: onOpenCalendar,
                          child: Text('Lihat ${todays.length} sesi'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
