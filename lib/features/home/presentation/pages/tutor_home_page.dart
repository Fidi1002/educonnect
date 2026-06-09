import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/availability/application/tutor_availability_controller.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:educonnect/features/availability/presentation/pages/tutor_availability_page.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_study_calendar_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_students_page.dart';
import 'package:educonnect/features/notifications/application/notification_controller.dart';
import 'package:educonnect/features/notifications/presentation/pages/notifications_page.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_stats_page.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
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
    final tutorProfileAsync = ref.watch(myTutorProfileProvider);
    final sessionsAsync = ref.watch(myTutorSessionsProvider);
    final bookingsAsync = ref.watch(myTutorBookingsProvider);
    final availabilityAsync = ref.watch(myTutorAvailabilityProvider);
    final pendingHomeworkAsync = ref.watch(myTutorPendingHomeworkProvider);
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
        tutorProfile: tutorProfileAsync.valueOrNull,
        pendingCount: pendingCount,
        waitingPaymentCount: waitingPaymentCount,
        unreadChatCount: unreadChatCount,
        unreadNotifications: unreadNotifications,
        sessionsAsync: sessionsAsync,
        bookingsAsync: bookingsAsync,
        availabilityAsync: availabilityAsync,
        pendingHomeworkAsync: pendingHomeworkAsync,
        onLogout: () => ref.read(authControllerProvider).signOut(),
      ),
      loading: () =>
          const AppLoadingState(message: 'Memuat dashboard tutor...'),
      error: (error, _) => _TutorHomeScaffold(
        profile: null,
        tutorProfile: tutorProfileAsync.valueOrNull,
        pendingCount: pendingCount,
        waitingPaymentCount: waitingPaymentCount,
        unreadChatCount: unreadChatCount,
        unreadNotifications: unreadNotifications,
        sessionsAsync: sessionsAsync,
        bookingsAsync: bookingsAsync,
        availabilityAsync: availabilityAsync,
        pendingHomeworkAsync: pendingHomeworkAsync,
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
    required this.tutorProfile,
    required this.pendingCount,
    required this.waitingPaymentCount,
    required this.unreadChatCount,
    required this.unreadNotifications,
    required this.sessionsAsync,
    required this.bookingsAsync,
    required this.availabilityAsync,
    required this.pendingHomeworkAsync,
    required this.onLogout,
    this.profileError,
  });

  final AppUserProfile? profile;
  final TutorProfile? tutorProfile;
  final int pendingCount;
  final int waitingPaymentCount;
  final int unreadChatCount;
  final int unreadNotifications;
  final AsyncValue<List<BookingSession>> sessionsAsync;
  final AsyncValue<List<BookingItem>> bookingsAsync;
  final AsyncValue<List<TutorAvailabilitySlot>> availabilityAsync;
  final AsyncValue<List<SessionLearningRecord>> pendingHomeworkAsync;
  final Future<void> Function() onLogout;
  final String? profileError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tutorName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Tutor';
    final now = DateTime.now();
    final bookings = bookingsAsync.valueOrNull ?? const <BookingItem>[];
    final sessions = sessionsAsync.valueOrNull ?? const <BookingSession>[];
    final availability =
        availabilityAsync.valueOrNull ?? const <TutorAvailabilitySlot>[];
    final pendingHomeworkCount = pendingHomeworkAsync.valueOrNull?.length ?? 0;
    final pendingHomeworkRecords =
        pendingHomeworkAsync.valueOrNull ?? const <SessionLearningRecord>[];
    final firstPendingHomework = pendingHomeworkRecords.isEmpty
        ? null
        : (pendingHomeworkRecords.toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
              .first;

    final activeBookings = bookings
        .where((booking) {
          return booking.status == BookingStatus.awaitingPayment ||
              booking.status == BookingStatus.paid;
        })
        .toList(growable: false);
    final activeStudents = activeBookings
        .map((booking) => booking.studentUid)
        .toSet()
        .length;
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrow = todayStart.add(const Duration(days: 1));
    final todaySessions = sessions
        .where((session) {
          return !session.sessionStart.isBefore(todayStart) &&
              session.sessionStart.isBefore(tomorrow);
        })
        .toList(growable: false);
    final upcomingSessions = sessions.where((session) {
      return session.sessionStart.isAfter(now) &&
          (session.status == BookingSessionStatus.scheduled ||
              session.status == BookingSessionStatus.donePendingConfirmation);
    }).toList()..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
    final reviewNeededCount = sessions.where((session) {
      return session.status == BookingSessionStatus.disputedPending ||
          session.status == BookingSessionStatus.donePendingConfirmation;
    }).length;
    final weekRangeStart = todayStart.subtract(
      Duration(days: todayStart.weekday - 1),
    );
    final nextWeekStart = weekRangeStart.add(const Duration(days: 7));
    final monthRangeStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    int countSessionsInRange(DateTime start, DateTime end) {
      return sessions.where((session) {
        return !session.sessionStart.isBefore(start) &&
            session.sessionStart.isBefore(end);
      }).length;
    }

    int countConfirmedInRange(DateTime start, DateTime end) {
      return sessions.where((session) {
        final isInRange =
            !session.sessionStart.isBefore(start) &&
            session.sessionStart.isBefore(end);
        final isFinal =
            session.status == BookingSessionStatus.confirmed ||
            session.status == BookingSessionStatus.disputedResolved;
        return isInRange && isFinal;
      }).length;
    }

    int countTutorNoShowInRange(DateTime start, DateTime end) {
      return sessions.where((session) {
        return !session.sessionStart.isBefore(start) &&
            session.sessionStart.isBefore(end) &&
            session.status == BookingSessionStatus.tutorNoShow;
      }).length;
    }

    int countBookingsInRange(DateTime start, DateTime end) {
      return bookings.where((booking) {
        return !booking.createdAt.isBefore(start) &&
            booking.createdAt.isBefore(end);
      }).length;
    }

    final weeklySessionCount = countSessionsInRange(
      weekRangeStart,
      nextWeekStart,
    );
    final weeklyConfirmedCount = countConfirmedInRange(
      weekRangeStart,
      nextWeekStart,
    );
    final weeklyTutorNoShowCount = countTutorNoShowInRange(
      weekRangeStart,
      nextWeekStart,
    );
    final monthlySessionCount = countSessionsInRange(
      monthRangeStart,
      nextMonthStart,
    );
    final monthlyConfirmedCount = countConfirmedInRange(
      monthRangeStart,
      nextMonthStart,
    );
    final monthlyBookingCount = countBookingsInRange(
      monthRangeStart,
      nextMonthStart,
    );
    final hasBackgroundLoading =
        sessionsAsync.isLoading ||
        bookingsAsync.isLoading ||
        availabilityAsync.isLoading ||
        pendingHomeworkAsync.isLoading;
    final backgroundErrors = <String>[
      if (sessionsAsync.hasError) 'jadwal sesi',
      if (bookingsAsync.hasError) 'data booking',
      if (availabilityAsync.hasError) 'availability',
      if (pendingHomeworkAsync.hasError) 'ringkasan PR',
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          _BadgeIconButton(
            count: unreadNotifications,
            onTap: () => context.pushNamed(NotificationsPage.routeName),
            icon: FluentIcons.alert_24_regular,
          ),
          _BadgeIconButton(
            count: unreadChatCount,
            onTap: () => context.pushNamed(InboxPage.routeName),
            icon: FluentIcons.chat_24_regular,
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(FluentIcons.sign_out_24_regular),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Tutor Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF4B176E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          if (profileError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.wifi_off_24_regular,
                    color: colorScheme.onErrorContainer,
                  ),
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
          if (backgroundErrors.isNotEmpty) ...[
            AppErrorState(
              message: 'Sebagian data dashboard tutor belum berhasil dimuat.',
              detail:
                  'Bagian yang terdampak: ${backgroundErrors.join(', ')}. Dashboard tetap menampilkan data terakhir yang tersedia.',
              fullScreen: false,
            ),
            const SizedBox(height: 12),
          ] else if (hasBackgroundLoading) ...[
            const AppLoadingState(
              message: 'Menyegarkan ringkasan dashboard tutor...',
              fullScreen: false,
            ),
            const SizedBox(height: 12),
          ],
          _TutorHeroCard(
            tutorName: tutorName,
            rating: tutorProfile?.rating ?? 0,
            totalReviews: tutorProfile?.totalReviews ?? 0,
            consistencyScore: tutorProfile?.consistencyScore ?? 0,
            activeStudents: activeStudents,
            pendingHomeworkCount: pendingHomeworkCount,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _MetricCard(
                title: 'Sesi Hari Ini',
                value: '${todaySessions.length}',
                note: todaySessions.isEmpty
                    ? 'Belum ada sesi untuk hari ini'
                    : 'Fokus pada kelas terdekatmu',
                icon: FluentIcons.calendar_empty_24_regular,
                color: const Color(0xFFF7F9FF),
                accentColor: const Color(0xFF4B176E),
              ),
              _MetricCard(
                title: 'Booking Baru',
                value: '$pendingCount',
                note: pendingCount == 0
                    ? 'Belum ada booking yang menunggu respon'
                    : 'Segera respon booking baru',
                icon: FluentIcons.mail_unread_24_regular,
                color: const Color(0xFFF7F9FF),
                accentColor: const Color(0xFFFF1377),
              ),
              _MetricCard(
                title: 'Menunggu Bayar',
                value: '$waitingPaymentCount',
                note: waitingPaymentCount == 0
                    ? 'Belum ada pembayaran yang tertunda'
                    : 'Pantau progres pembayaran murid',
                icon: FluentIcons.money_24_regular,
                color: const Color(0xFFF7F9FF),
                accentColor: const Color(0xFF4B176E),
              ),
              _MetricCard(
                title: 'Perlu Review',
                value: '$reviewNeededCount',
                note: reviewNeededCount == 0
                    ? 'Belum ada sesi yang perlu ditinjau'
                    : 'Tinjau sesi yang masih pending',
                icon: Icons.rule_folder_outlined,
                color: const Color(0xFFF7F9FF),
                accentColor: const Color(0xFFFF1377),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TodayFocusCard(
            todaySessions: todaySessions,
            bookings: bookings,
            onOpenCalendar: () =>
                context.pushNamed(TutorStudyCalendarPage.routeName),
            onOpenBooking: (bookingId, sessionId) => context.pushNamed(
              TutorBookingsPage.routeName,
              queryParameters: {'bookingId': bookingId, 'sessionId': sessionId},
            ),
          ),
          const SizedBox(height: 14),
          _WindowStatsSection(
            weeklySessionCount: weeklySessionCount,
            weeklyConfirmedCount: weeklyConfirmedCount,
            weeklyTutorNoShowCount: weeklyTutorNoShowCount,
            monthlySessionCount: monthlySessionCount,
            monthlyConfirmedCount: monthlyConfirmedCount,
            monthlyBookingCount: monthlyBookingCount,
          ),
          const SizedBox(height: 14),
          _TutorStatusStrip(
            activeStudents: activeStudents,
            nextSession: upcomingSessions.isEmpty
                ? null
                : upcomingSessions.first,
            bookings: bookings,
            availability: availability,
            onOpenStudents: () =>
                context.pushNamed(TutorStudentsPage.routeName),
            onOpenAvailability: () =>
                context.pushNamed(TutorAvailabilityPage.routeName),
          ),
          const SizedBox(height: 14),
          _QuickHomeworkCard(
            pendingHomeworkCount: pendingHomeworkCount,
            onOpenStudents: () =>
                context.pushNamed(TutorStudentsPage.routeName),
            onReviewLatest: firstPendingHomework == null
                ? null
                : () => context.pushNamed(
                    TutorBookingsPage.routeName,
                    queryParameters: {
                      'bookingId': firstPendingHomework.bookingId,
                      'sessionId': firstPendingHomework.sessionId,
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  const _BadgeIconButton({
    required this.count,
    required this.onTap,
    required this.icon,
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

class _TutorHeroCard extends StatelessWidget {
  const _TutorHeroCard({
    required this.tutorName,
    required this.rating,
    required this.totalReviews,
    required this.consistencyScore,
    required this.activeStudents,
    required this.pendingHomeworkCount,
  });

  final String tutorName;
  final double rating;
  final int totalReviews;
  final double consistencyScore;
  final int activeStudents;
  final int pendingHomeworkCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: TutorUi.heroGradientPrimary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tutor Command Center',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: () => context.pushNamed(TutorStatsPage.routeName),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.data_trending_24_regular,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Detail Analitik',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Halo, $tutorName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pantau kelas aktif, PR yang harus direview, dan ritme mengajarmu dari satu tempat.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                label: 'Rating',
                value: '${rating.toStringAsFixed(1)} ($totalReviews ulasan)',
              ),
              _HeroPill(
                label: 'Consistency',
                value: '${consistencyScore.toStringAsFixed(0)}%',
              ),
              _HeroPill(label: 'Murid Aktif', value: '$activeStudents / 2'),
              _HeroPill(label: 'PR Pending', value: '$pendingHomeworkCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = isDark ? const Color(0xFF1B2336) : color;
    final displayBorderColor = isDark ? const Color(0xFF28354E) : const Color(0xFFC9D8F2);
    final displayAccentColor = isDark
        ? (accentColor == const Color(0xFF4B176E) ? const Color(0xFFFF1377) : accentColor)
        : accentColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: displayColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: displayBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: displayAccentColor),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(note, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({
    required this.todaySessions,
    required this.bookings,
    required this.onOpenCalendar,
    required this.onOpenBooking,
  });

  final List<BookingSession> todaySessions;
  final List<BookingItem> bookings;
  final VoidCallback onOpenCalendar;
  final void Function(String bookingId, String sessionId) onOpenBooking;

  @override
  Widget build(BuildContext context) {
    final bookingMap = <String, BookingItem>{
      for (final booking in bookings) booking.id: booking,
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1B2336) : Colors.white;
    final displayBorder = isDark ? Border.all(color: const Color(0xFF28354E)) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(22),
        border: displayBorder,
        boxShadow: isDark ? null : const [TutorUi.mediumShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fokus Hari Ini',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: onOpenCalendar,
                child: const Text('Kalender'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            todaySessions.isEmpty
                ? 'Belum ada sesi hari ini. Kamu bisa memakai waktu ini untuk merapikan availability dan PR.'
                : 'Berikut sesi terdekat yang perlu kamu pantau hari ini.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (todaySessions.isEmpty)
            const _SoftEmptyState(message: 'Tidak ada sesi mengajar hari ini.')
          else
            ...todaySessions.take(3).map((session) {
              final booking = bookingMap[session.bookingId];
              final studentName = booking?.studentName ?? 'Murid';
              final subject = booking?.subject ?? 'Sesi Mengajar';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF090D16) : const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        FluentIcons.hat_graduation_24_regular,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(studentName),
                          const SizedBox(height: 2),
                          Text(
                            '${session.sessionStart.hour.toString().padLeft(2, '0')}:${session.sessionStart.minute.toString().padLeft(2, '0')}'
                            ' - ${session.sessionEnd.hour.toString().padLeft(2, '0')}:${session.sessionEnd.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          onOpenBooking(session.bookingId, session.id),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TutorStatusStrip extends StatelessWidget {
  const _TutorStatusStrip({
    required this.activeStudents,
    required this.nextSession,
    required this.bookings,
    required this.availability,
    required this.onOpenStudents,
    required this.onOpenAvailability,
  });

  final int activeStudents;
  final BookingSession? nextSession;
  final List<BookingItem> bookings;
  final List<TutorAvailabilitySlot> availability;
  final VoidCallback onOpenStudents;
  final VoidCallback onOpenAvailability;

  @override
  Widget build(BuildContext context) {
    final bookedSubjects = bookings
        .where((booking) => booking.status == BookingStatus.paid)
        .map((booking) => booking.subject)
        .toSet()
        .length;
    final activeDays = availability.map((slot) => slot.weekday).toSet().length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ActionInfoCard(
            title: 'Murid Aktif',
            value: '$activeStudents / 2',
            subtitle: bookedSubjects == 0
                ? 'Belum ada mapel aktif saat ini'
                : '$bookedSubjects mapel aktif berjalan',
            buttonLabel: 'Lihat Murid',
            onTap: onOpenStudents,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionInfoCard(
            title: 'Availability',
            value: '$activeDays hari',
            subtitle: nextSession == null
                ? 'Belum ada sesi berikutnya'
                : 'Next ${nextSession!.sessionStart.day}/${nextSession!.sessionStart.month}',
            buttonLabel: 'Atur Slot',
            onTap: onOpenAvailability,
          ),
        ),
      ],
    );
  }
}

class _ActionInfoCard extends StatelessWidget {
  const _ActionInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TutorUi.elevatedCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onTap, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _QuickHomeworkCard extends StatelessWidget {
  const _QuickHomeworkCard({
    required this.pendingHomeworkCount,
    required this.onOpenStudents,
    required this.onReviewLatest,
  });

  final int pendingHomeworkCount;
  final VoidCallback onOpenStudents;
  final VoidCallback? onReviewLatest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TutorUi.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0x26FFFFFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.assignment_turned_in, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan PR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingHomeworkCount == 0
                      ? 'Tidak ada PR yang menunggu review saat ini.'
                      : '$pendingHomeworkCount PR sedang menunggu review tutor.',
                  style: const TextStyle(color: Color(0xFFD8E7EA)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              FilledButton.tonal(
                onPressed: onOpenStudents,
                child: const Text('Cek'),
              ),
              if (onReviewLatest != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onReviewLatest,
                  child: const Text('Review Cepat'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowStatsSection extends StatelessWidget {
  const _WindowStatsSection({
    required this.weeklySessionCount,
    required this.weeklyConfirmedCount,
    required this.weeklyTutorNoShowCount,
    required this.monthlySessionCount,
    required this.monthlyConfirmedCount,
    required this.monthlyBookingCount,
  });

  final int weeklySessionCount;
  final int weeklyConfirmedCount;
  final int weeklyTutorNoShowCount;
  final int monthlySessionCount;
  final int monthlyConfirmedCount;
  final int monthlyBookingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PeriodCard(
            title: 'Minggu Ini',
            accent: const Color(0xFF2D6072),
            metrics: [
              ('Sesi', '$weeklySessionCount'),
              ('Final', '$weeklyConfirmedCount'),
              ('Tutor No-show', '$weeklyTutorNoShowCount'),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PeriodCard(
            title: 'Bulan Ini',
            accent: const Color(0xFF7A4A1D),
            metrics: [
              ('Sesi', '$monthlySessionCount'),
              ('Final', '$monthlyConfirmedCount'),
              ('Booking Baru', '$monthlyBookingCount'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.title,
    required this.accent,
    required this.metrics,
  });

  final String title;
  final Color accent;
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayAccent = isDark
        ? (accent == const Color(0xFF2D6072) ? const Color(0xFF38BDF8) : const Color(0xFFFB923C))
        : accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: displayAccent,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(child: Text(metric.$1)),
                  Text(
                    metric.$2,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftEmptyState extends StatelessWidget {
  const _SoftEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}
