import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/session_change_request.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:educonnect/features/tutor/application/tutor_review_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatDateTimeShort(DateTime value) {
  return '${value.day}/${value.month}/${value.year} • ${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}

String _formatWeekdayScheduleLabel(Iterable<dynamic> slots) {
  return slots
      .map((slot) => '${slot.weekdayLabel} ${slot.timeLabel}')
      .join(' • ');
}

class StudentBookingsPage extends ConsumerStatefulWidget {
  const StudentBookingsPage({super.key});

  static const routeName = 'student-bookings';
  static const routePath = '/student/bookings';

  @override
  ConsumerState<StudentBookingsPage> createState() =>
      _StudentBookingsPageState();
}

class _StudentBookingsPageState extends ConsumerState<StudentBookingsPage> {
  final Map<String, GlobalKey> _sessionAnchorKeys = <String, GlobalKey>{};
  String? _lastAutoScrolledSessionId;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myStudentBookingsProvider);
    final isLoading = ref.watch(bookingLoadingProvider);
    final query = GoRouterState.of(context).uri.queryParameters;
    final focusedBookingId = query['bookingId'];
    final focusedSessionId = query['sessionId'];
    final focusedSessionKey = focusedSessionId == null
        ? null
        : _sessionAnchorKeys.putIfAbsent(
            focusedSessionId,
            () => GlobalKey(debugLabel: 'session-$focusedSessionId'),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Saya')),
      body: bookingsAsync.when(
        data: (items) {
          final now = DateTime.now();
          final upcoming =
              items
                  .where((item) => isStudentUpcomingBooking(item, now: now))
                  .toList()
                ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
          _bringFocusedBookingToFront(upcoming, focusedBookingId);
          final history =
              items
                  .where((item) => !isStudentUpcomingBooking(item, now: now))
                  .toList()
                ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));
          _bringFocusedBookingToFront(history, focusedBookingId);
          final initialTab = history.any((item) => item.id == focusedBookingId)
              ? 1
              : 0;

          _scheduleAutoScrollToSession(
            focusedSessionId: focusedSessionId,
            focusedSessionKey: focusedSessionKey,
          );

          return DefaultTabController(
            length: 2,
            initialIndex: initialTab,
            child: Column(
              children: [
                _StudentBookingOverview(
                  allItems: items,
                  upcomingItems: upcoming,
                  historyItems: history,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD3DFFB)),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: const Color(0xFFFF1377),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF1377,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF756E81),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Akan Datang'),
                      Tab(text: 'Riwayat'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _BookingList(
                        items: upcoming,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada booking aktif saat ini.',
                        onPay: (bookingId, paymentMethod) =>
                            _payWebhook(bookingId, paymentMethod),
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                      _BookingList(
                        items: history,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada riwayat booking.',
                        onPay: (bookingId, paymentMethod) =>
                            _payWebhook(bookingId, paymentMethod),
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingState(
          message: 'Memuat jadwal belajar...',
          fullScreen: false,
        ),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat jadwal saya.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myStudentBookingsProvider),
        ),
      ),
    );
  }

  void _scheduleAutoScrollToSession({
    required String? focusedSessionId,
    required GlobalKey? focusedSessionKey,
  }) {
    if (focusedSessionId == null ||
        focusedSessionId.isEmpty ||
        focusedSessionKey == null) {
      return;
    }
    if (_lastAutoScrolledSessionId == focusedSessionId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = focusedSessionKey.currentContext;
      if (ctx == null || !mounted) {
        return;
      }
      _lastAutoScrolledSessionId = focusedSessionId;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _payWebhook(String bookingId, String paymentMethod) async {
    try {
      await ref
          .read(bookingControllerProvider)
          .paySecureWebhookBooking(
            bookingId: bookingId,
            paymentMethod: paymentMethod,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pembayaran berhasil dikonfirmasi via Webhook Server!',
          ),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memproses verifikasi webhook. ${error.toString()}',
          ),
        ),
      );
    }
  }

  void _bringFocusedBookingToFront(List<BookingItem> items, String? bookingId) {
    if (bookingId == null || bookingId.isEmpty || items.isEmpty) {
      return;
    }
    final index = items.indexWhere((item) => item.id == bookingId);
    if (index <= 0) {
      return;
    }
    final focused = items.removeAt(index);
    items.insert(0, focused);
  }
}

class _StudentBookingOverview extends StatelessWidget {
  const _StudentBookingOverview({
    required this.allItems,
    required this.upcomingItems,
    required this.historyItems,
  });

  final List<BookingItem> allItems;
  final List<BookingItem> upcomingItems;
  final List<BookingItem> historyItems;

  @override
  Widget build(BuildContext context) {
    final awaitingPayment = allItems
        .where((item) => item.status == BookingStatus.awaitingPayment)
        .length;
    final active = allItems
        .where((item) => item.status == BookingStatus.paid)
        .length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F7FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD9E4FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1E1E59),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Booking & Jadwal',
                  style: TextStyle(
                    color: Color(0xFF4B176E),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                FluentIcons.calendar_ltr_24_regular,
                color: Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ringkasan Booking Belajar',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Pantau paket aktif, pembayaran, status sesi, dan riwayat belajar dari satu tempat.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF756E81)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewMetricPill(
                  label: 'Akan datang',
                  value: '${upcomingItems.length}',
                  accent: const Color(0xFF4B176E),
                  icon: FluentIcons.clock_24_regular,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetricPill(
                  label: 'Aktif',
                  value: '$active',
                  accent: const Color(0xFF6366F1),
                  icon: FluentIcons.book_open_24_regular,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetricPill(
                  label: 'Riwayat',
                  value: '${historyItems.length}',
                  accent: const Color(0xFFFF1377),
                  icon: FluentIcons.history_24_regular,
                ),
              ),
            ],
          ),
          if (awaitingPayment > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    FluentIcons.money_24_regular,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$awaitingPayment booking masih menunggu pembayaran agar jadwal aktif penuh.',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewMetricPill extends StatelessWidget {
  const _OverviewMetricPill({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF736A81),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.items,
    required this.isLoading,
    required this.emptyMessage,
    required this.onPay,
    required this.focusedSessionId,
    required this.focusedSessionKey,
  });

  final List<BookingItem> items;
  final bool isLoading;
  final String emptyMessage;
  final void Function(String bookingId, String paymentMethod) onPay;
  final String? focusedSessionId;
  final GlobalKey? focusedSessionKey;

  Future<void> _showMockPaymentGateway(
    BuildContext context,
    BookingItem item,
  ) async {
    final paymentMethod = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SecureCheckoutSheet(item: item);
      },
    );

    if (paymentMethod != null) {
      onPay(item.id, paymentMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(
        message: emptyMessage,
        hint:
            'Setelah booking diproses atau riwayat kelas terbentuk, detailnya akan muncul di sini.',
        icon: FluentIcons.book_24_regular,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _BookingCard(
              item: item,
              paymentLoading: isLoading,
              onPay: item.status == BookingStatus.awaitingPayment
                  ? () => _showMockPaymentGateway(context, item)
                  : null,
              focusedSessionId: focusedSessionId,
              focusedSessionKey: focusedSessionKey,
            )
            .animate()
            .fade(delay: (index * 50).ms, duration: 400.ms)
            .slideY(begin: 0.1, curve: Curves.easeOut);
      },
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({
    required this.item,
    required this.paymentLoading,
    this.onPay,
    this.focusedSessionId,
    this.focusedSessionKey,
  });

  final BookingItem item;
  final bool paymentLoading;
  final VoidCallback? onPay;
  final String? focusedSessionId;
  final GlobalKey? focusedSessionKey;

  List<BookingSession> _selectDisplayedSessions(
    List<BookingSession> sessions,
    String? targetSessionId,
  ) {
    if (targetSessionId == null ||
        targetSessionId.isEmpty ||
        sessions.length <= 3) {
      return sessions.take(3).toList(growable: false);
    }

    final focusIndex = sessions.indexWhere(
      (session) => session.id == targetSessionId,
    );
    if (focusIndex < 0 || focusIndex < 3) {
      return sessions.take(3).toList(growable: false);
    }

    return <BookingSession>[sessions[0], sessions[1], sessions[focusIndex]];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(bookingSessionsProvider(item.id));
    final requestsAsync = ref.watch(sessionChangeRequestsProvider(item.id));
    final learningAsync = ref.watch(sessionLearningRecordsProvider(item.id));
    final currentUid = ref.watch(authStateProvider).value?.uid ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1E1E59),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF4B176E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tutor: ${item.tutorName.isEmpty ? item.tutorUid : item.tutorName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6F7280),
                        ),
                      ),
                    ],
                  ),
                ),
                _BookingStatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.calendar_month_outlined,
                  label:
                      '${item.packageMonths} bulan • ${item.sessionsPerWeek}x/minggu',
                  accent: const Color(0xFF4B176E),
                ),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: _formatDateTimeShort(item.sessionStart),
                  accent: const Color(0xFF6366F1),
                ),
                _InfoChip(
                  icon: FluentIcons.money_24_regular,
                  label: item.paidAt == null
                      ? 'Menunggu pembayaran'
                      : 'Pembayaran tuntas',
                  accent: item.paidAt == null
                      ? const Color(0xFFB45309)
                      : const Color(0xFF0F766E),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE4F3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Paket',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF4B176E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Periode: ${item.packageStartDate.day}/${item.packageStartDate.month}/${item.packageStartDate.year}'
                    ' - ${item.packageEndDate.day}/${item.packageEndDate.month}/${item.packageEndDate.year}',
                  ),
                  if (item.weeklySchedule.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Jadwal tetap: ${_formatWeekdayScheduleLabel(item.weeklySchedule)}',
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text('Durasi: ${item.durationMinutes} menit'),
                  Text('Biaya: Rp ${item.totalAmount}'),
                  if (item.paidAt != null) ...[
                    const SizedBox(height: 4),
                    Text('Dibayar: ${_formatDateTimeShort(item.paidAt!)}'),
                  ],
                  if (item.message.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Catatan: ${item.message}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Progress Pertemuan',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const AppEmptyState(
                    message: 'Belum ada data pertemuan.',
                    hint:
                        'Sesi akan tampil setelah booking diproses dan jadwal terbentuk.',
                    icon: Icons.event_busy_outlined,
                  );
                }
                final confirmedCount = sessions
                    .where(
                      (session) =>
                          session.status == BookingSessionStatus.confirmed ||
                          session.status ==
                              BookingSessionStatus.disputedResolved,
                    )
                    .length;
                final progressPercent =
                    ((confirmedCount / sessions.length) * 100).round();
                final shortlist = _selectDisplayedSessions(
                  sessions,
                  focusedSessionId,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      shortlist.map((session) {
                        final isFocusedSession =
                            focusedSessionId != null &&
                            focusedSessionId!.isNotEmpty &&
                            session.id == focusedSessionId;
                        final request = _findPendingRequest(
                          session.id,
                          requestsAsync.valueOrNull ?? const [],
                        );
                        final learningRecord = _findLearningRecord(
                          session.id,
                          learningAsync.valueOrNull ?? const [],
                        );
                        final canConfirm =
                            session.status ==
                            BookingSessionStatus.donePendingConfirmation;
                        final canRequestChange =
                            request == null &&
                            session.status == BookingSessionStatus.scheduled &&
                            session.sessionStart.isAfter(DateTime.now());
                        final canConfirmPresence =
                            session.studentPresenceConfirmedAt == null &&
                            (session.status == BookingSessionStatus.scheduled || session.status == BookingSessionStatus.inProgress) &&
                            (session.sessionStart.isAfter(DateTime.now()) || session.status == BookingSessionStatus.inProgress) &&
                            session.sessionStart.isBefore(
                              DateTime.now().add(const Duration(hours: 24)),
                            );
                        final canMarkTutorNoShow =
                            (session.status == BookingSessionStatus.scheduled || session.status == BookingSessionStatus.inProgress) &&
                            session.sessionEnd.isBefore(DateTime.now());
                        final canSubmitHomework =
                            learningRecord != null &&
                            learningRecord.homeworkStatus ==
                                HomeworkStatus.assigned;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            key: isFocusedSession ? focusedSessionKey : null,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isFocusedSession
                                  ? const Color(0xFFF8F0FF)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                              border: isFocusedSession
                                  ? Border.all(
                                      color: const Color(0xFF7B2CBF),
                                      width: 1.4,
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${session.sessionStart.day}/${session.sessionStart.month} '
                                  '${session.sessionStart.hour.toString().padLeft(2, '0')}:${session.sessionStart.minute.toString().padLeft(2, '0')}'
                                  ' - ${session.sessionEnd.hour.toString().padLeft(2, '0')}:${session.sessionEnd.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _SessionStatusBadge(status: session.status),
                                if (isFocusedSession) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEDCFF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Sesi dari notifikasi',
                                      style: TextStyle(
                                        color: Color(0xFF6B21A8),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                if (session.studentPresenceConfirmedAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Hadir dikonfirmasi '
                                      '${session.studentPresenceConfirmedAt!.hour.toString().padLeft(2, '0')}:'
                                      '${session.studentPresenceConfirmedAt!.minute.toString().padLeft(2, '0')}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                if (learningRecord != null &&
                                    (learningRecord.hasMaterial ||
                                        learningRecord.hasHomework)) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Learning Journal',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: const Color(0xFF4B176E),
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        if (learningRecord.hasMaterial) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Materi: ${learningRecord.materialSummary}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                        if (learningRecord.materialNotes
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Catatan: ${learningRecord.materialNotes}',
                                          ),
                                        ],
                                        if (learningRecord.hasHomework) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'PR: ${learningRecord.homeworkTitle}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (learningRecord.homeworkDescription
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              learningRecord
                                                  .homeworkDescription,
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            'Status PR: ${learningRecord.homeworkStatus.label}',
                                          ),
                                          if (learningRecord.studentSubmission
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Jawaban saya: ${learningRecord.studentSubmission}',
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                if (request != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Request ${request.requestType} menunggu persetujuan',
                                    style: const TextStyle(
                                      color: Color(0xFF8C4BC0),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (request.targetUid == currentUid) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: paymentLoading
                                                ? null
                                                : () => ref
                                                      .read(
                                                        bookingControllerProvider,
                                                      )
                                                      .respondSessionChangeRequest(
                                                        requestId: request.id,
                                                        approved: false,
                                                      ),
                                            child: const Text('Tolak'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: paymentLoading
                                                ? null
                                                : () => ref
                                                      .read(
                                                        bookingControllerProvider,
                                                      )
                                                      .respondSessionChangeRequest(
                                                        requestId: request.id,
                                                        approved: true,
                                                      ),
                                            child: const Text('Setujui'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                                if (canConfirm) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: paymentLoading
                                              ? null
                                              : () async {
                                                  await ref
                                                      .read(
                                                        bookingControllerProvider,
                                                      )
                                                      .disputeSessionByStudent(
                                                        session.id,
                                                      );
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Sesi ditandai bermasalah dan akan ditinjau bersama tutor.',
                                                      ),
                                                    ),
                                                  );
                                                },
                                          child: const Text('Tidak Berjalan'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: paymentLoading
                                              ? null
                                              : () async {
                                                  try {
                                                    await _showConfirmDialog(
                                                      context: context,
                                                      ref: ref,
                                                      sessionId: session.id,
                                                    );
                                                  } on Exception catch (error) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Gagal mengonfirmasi sesi. Coba lagi sebentar lagi. ${error.toString()}',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: const Text('Konfirmasi'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (canMarkTutorNoShow) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: paymentLoading
                                          ? null
                                          : () async {
                                              try {
                                                await ref
                                                    .read(
                                                      bookingControllerProvider,
                                                    )
                                                    .markTutorNoShow(
                                                      session.id,
                                                    );
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Sesi berhasil ditandai sebagai tutor tidak hadir.',
                                                    ),
                                                  ),
                                                );
                                              } on Exception catch (error) {
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Gagal memperbarui kehadiran tutor. Coba lagi. ${error.toString()}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      icon: const Icon(
                                        FluentIcons
                                            .person_prohibited_24_regular,
                                      ),
                                      label: const Text('Tutor Tidak Hadir'),
                                    ),
                                  ),
                                ],
                                if (session.status == BookingSessionStatus.disputedPending) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showDisputeSupportDialog(context),
                                      icon: const Icon(Icons.support_agent, color: Colors.white, size: 16),
                                      label: const Text('Hubungi Dukungan CS (Mediasi)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFDC2626), // Merah untuk urgensi
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (canRequestChange) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: paymentLoading
                                              ? null
                                              : () => _showCancelRequestDialog(
                                                  context: context,
                                                  ref: ref,
                                                  sessionId: session.id,
                                                ),
                                          child: const Text('Ajukan Batal'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: paymentLoading
                                              ? null
                                              : () =>
                                                    _showRescheduleRequestDialog(
                                                      context: context,
                                                      ref: ref,
                                                      sessionId: session.id,
                                                      durationMinutes:
                                                          item.durationMinutes,
                                                    ),
                                          child: const Text(
                                            'Ajukan Reschedule',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (canConfirmPresence) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                      onPressed: paymentLoading
                                          ? null
                                          : () async {
                                              await ref
                                                  .read(
                                                    bookingControllerProvider,
                                                  )
                                                  .confirmSessionPresence(
                                                    session.id,
                                                  );
                                              if (!context.mounted) {
                                                return;
                                              }
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Kehadiran berhasil dikonfirmasi untuk sesi ini.',
                                                  ),
                                                ),
                                              );
                                            },
                                      icon: const Icon(
                                        Icons.how_to_reg_outlined,
                                      ),
                                      label: Text(
                                        isFocusedSession
                                            ? 'Konfirmasi Hadir (Sesi Ini)'
                                            : 'Konfirmasi Hadir',
                                      ),
                                    ),
                                  ),
                                ],
                                if (canSubmitHomework) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.tonalIcon(
                                      onPressed: paymentLoading
                                          ? null
                                          : () => _showHomeworkSubmitDialog(
                                              context: context,
                                              ref: ref,
                                              sessionId: session.id,
                                            ),
                                      icon: const Icon(
                                        Icons.assignment_turned_in,
                                      ),
                                      label: const Text('Kumpulkan PR'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList()..insert(
                        0,
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Progress: $confirmedCount/${sessions.length} sesi',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text('$progressPercent%'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: confirmedCount / sessions.length,
                                  backgroundColor: const Color(0xFFE9E3F2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF4B176E),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: AppLoadingState(
                  message: 'Memuat progress pertemuan...',
                  fullScreen: false,
                ),
              ),
              error: (error, _) => AppErrorState(
                message: 'Gagal memuat sesi belajar.',
                detail: error.toString(),
                onRetry: () => ref.invalidate(bookingSessionsProvider(item.id)),
                fullScreen: false,
              ),
            ),
            const SizedBox(height: 10),
            if (item.status == BookingStatus.completed)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _ReviewBottomSheet(item: item),
                        );
                      },
                      icon: const Icon(FluentIcons.star_24_regular),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B), // Warna emas/premium
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('Beri Ulasan Tutor'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.pushNamed(
                        ChatPage.routeName,
                        pathParameters: {'bookingId': item.id},
                      ),
                      icon: const Icon(FluentIcons.chat_24_regular),
                      label: const Text('Chat'),
                    ),
                  ),
                ],
              )
            else if (onPay != null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: paymentLoading ? null : onPay,
                      icon: const Icon(FluentIcons.money_24_regular),
                      label: Text(
                        paymentLoading
                            ? 'Memverifikasi Webhook...'
                            : 'Bayar Sekarang',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.pushNamed(
                        ChatPage.routeName,
                        pathParameters: {'bookingId': item.id},
                      ),
                      icon: const Icon(FluentIcons.chat_24_regular),
                      label: const Text('Chat'),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  ChatPage.routeName,
                  pathParameters: {'bookingId': item.id},
                ),
                icon: const Icon(FluentIcons.chat_24_regular),
                label: const Text('Buka Chat'),
              ),
          ],
        ),
      ),
    );
  }

  SessionChangeRequest? _findPendingRequest(
    String sessionId,
    List<SessionChangeRequest> requests,
  ) {
    for (final request in requests) {
      if (request.sessionId == sessionId && request.isPending) {
        return request;
      }
    }
    return null;
  }

  SessionLearningRecord? _findLearningRecord(
    String sessionId,
    List<SessionLearningRecord> records,
  ) {
    for (final record in records) {
      if (record.sessionId == sessionId) {
        return record;
      }
    }
    return null;
  }

  void _showDisputeSupportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.support_agent, color: Color(0xFFDC2626), size: 28),
              SizedBox(width: 10),
              Text(
                'Mediasi Sesi Belajar',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sesi ini sedang berada dalam status perselisihan (Disputed). Tim EduConnect akan melakukan peninjauan laporan kehadiran dan aktivitas belajar.',
                style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
              ),
              SizedBox(height: 16),
              Text(
                'Hubungi Dukungan CS Resmi:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_android, size: 16, color: Color(0xFF4B176E)),
                  SizedBox(width: 8),
                  Text('WhatsApp: 0812-3456-7890', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Color(0xFF4B176E)),
                  SizedBox(width: 8),
                  Text('Email: support@educonnect.com', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelRequestDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
  }) async {
    final reasonController = TextEditingController();
    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ajukan Pembatalan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alasan pembatalan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Kirim'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (submit != true) {
      reasonController.dispose();
      return;
    }
    await ref
        .read(bookingControllerProvider)
        .requestSessionCancel(
          sessionId: sessionId,
          reason: reasonController.text,
        );
    reasonController.dispose();
  }

  Future<void> _showRescheduleRequestDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
    required int durationMinutes,
  }) async {
    final reasonController = TextEditingController();
    DateTime? selectedDateTime;

    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ajukan Reschedule',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 120)),
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 16, minute: 0),
                      );
                      if (time == null || !context.mounted) return;
                      setState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    icon: const Icon(FluentIcons.clock_24_regular),
                    label: Text(
                      selectedDateTime == null
                          ? 'Pilih jadwal baru'
                          : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} '
                                '${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Alasan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: selectedDateTime == null
                              ? null
                              : () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Kirim'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (submit != true || selectedDateTime == null) {
      reasonController.dispose();
      return;
    }
    await ref
        .read(bookingControllerProvider)
        .requestSessionReschedule(
          sessionId: sessionId,
          proposedStart: selectedDateTime!,
          proposedEnd: selectedDateTime!.add(
            Duration(minutes: durationMinutes),
          ),
          reason: reasonController.text,
        );
    reasonController.dispose();
  }

  Future<void> _showConfirmDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
  }) async {
    final reviewController = TextEditingController();
    var rating = 5;

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Konfirmasi Pertemuan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: rating,
                    decoration: const InputDecoration(
                      labelText: 'Rating Tutor',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 5,
                        child: Text('5 - Sangat Baik'),
                      ),
                      DropdownMenuItem(value: 4, child: Text('4 - Baik')),
                      DropdownMenuItem(value: 3, child: Text('3 - Cukup')),
                      DropdownMenuItem(value: 2, child: Text('2 - Kurang')),
                      DropdownMenuItem(value: 1, child: Text('1 - Buruk')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        rating = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ulasan (opsional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submit != true) {
      reviewController.dispose();
      return;
    }

    await ref
        .read(bookingControllerProvider)
        .confirmSessionByStudent(
          sessionId: sessionId,
          rating: rating,
          review: reviewController.text,
        );
    reviewController.dispose();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pertemuan terkonfirmasi. Terima kasih atas penilaianmu!',
        ),
      ),
    );
  }

  Future<void> _showHomeworkSubmitDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
  }) async {
    final submissionController = TextEditingController();
    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kumpulkan PR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: submissionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Jawaban / link tugas',
                hintText: 'Tulis jawaban atau tempel link tugasmu di sini',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Kirim'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (submit != true) {
      submissionController.dispose();
      return;
    }
    await ref
        .read(bookingControllerProvider)
        .submitHomework(
          sessionId: sessionId,
          submissionText: submissionController.text,
        );
    submissionController.dispose();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PR berhasil dikumpulkan dan menunggu review tutor.'),
      ),
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      BookingStatus.pending => (
        const Color(0xFFFFF3D5),
        const Color(0xFF9A6700),
      ),
      BookingStatus.awaitingPayment => (
        const Color(0xFFFFF0E5),
        const Color(0xFFB45309),
      ),
      BookingStatus.paid => (const Color(0xFFE7F8F1), const Color(0xFF0F766E)),
      BookingStatus.completed => (
        const Color(0xFFE9E8FF),
        const Color(0xFF4C1D95),
      ),
      BookingStatus.rejected => (
        const Color(0xFFFCE7E7),
        const Color(0xFFB91C1C),
      ),
      BookingStatus.cancelled => (
        const Color(0xFFEDEBF2),
        const Color(0xFF5B5563),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.$2,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SessionStatusBadge extends StatelessWidget {
  const _SessionStatusBadge({required this.status});

  final BookingSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      BookingSessionStatus.scheduled => (
        const Color(0xFFE6F3FF),
        const Color(0xFF0C4A6E),
      ),
      BookingSessionStatus.inProgress => (
        const Color(0xFFE1F5FE),
        const Color(0xFF0277BD),
      ),
      BookingSessionStatus.donePendingConfirmation => (
        const Color(0xFFFFF3D5),
        const Color(0xFF9A6700),
      ),
      BookingSessionStatus.confirmed => (
        const Color(0xFFE7F8F1),
        const Color(0xFF0F766E),
      ),
      BookingSessionStatus.disputedPending => (
        const Color(0xFFFCE7E7),
        const Color(0xFFB91C1C),
      ),
      BookingSessionStatus.disputedResolved => (
        const Color(0xFFEDE9FE),
        const Color(0xFF6D28D9),
      ),
      BookingSessionStatus.cancelledByStudent ||
      BookingSessionStatus.cancelledByTutor ||
      BookingSessionStatus.cancelledEarly ||
      BookingSessionStatus.cancelledLate => (
        const Color(0xFFEDEBF2),
        const Color(0xFF5B5563),
      ),
      BookingSessionStatus.rescheduled => (
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
      ),
      BookingSessionStatus.studentNoShow || BookingSessionStatus.tutorNoShow =>
        (const Color(0xFFFCE7E7), const Color(0xFF9F1239)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.$2,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.accent = const Color(0xFF4B176E),
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBottomSheet extends ConsumerStatefulWidget {
  const _ReviewBottomSheet({required this.item});
  final BookingItem item;

  @override
  ConsumerState<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends ConsumerState<_ReviewBottomSheet> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ctrl = ref.read(tutorReviewControllerProvider);
      final currentUid = ref.read(authStateProvider).value?.uid ?? '';
      
      await ctrl.submitReview(
        tutorUid: widget.item.tutorUid,
        studentUid: currentUid,
        bookingId: widget.item.id,
        rating: _rating,
        reviewText: comment,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih! Ulasan berhasil dikirim.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim ulasan')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bagaimana pengalaman belajarmu?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF191622),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return IconButton(
                onPressed: () {
                  setState(() => _rating = starValue);
                },
                icon: Icon(
                  starValue <= _rating
                      ? FluentIcons.star_24_filled
                      : FluentIcons.star_24_regular,
                  color: const Color(0xFFF59E0B),
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tutornya asik banget dan materinya jelas...',
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4B176E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Kirim Ulasan',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureCheckoutSheet extends StatefulWidget {
  const _SecureCheckoutSheet({
    required this.item,
  });

  final BookingItem item;

  @override
  State<_SecureCheckoutSheet> createState() => _SecureCheckoutSheetState();
}

class _SecureCheckoutSheetState extends State<_SecureCheckoutSheet> {
  String _selectedMethod = 'gopay'; // 'gopay' or 'bca_va'
  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  Widget build(BuildContext context) {
    const double serviceFee = 4000;
    final double totalBill = widget.item.totalAmount + serviceFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isProcessing
            ? _buildProcessingView()
            : _buildCheckoutView(totalBill, serviceFee),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            color: Color(0xFF7B2CBF),
            strokeWidth: 5,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _processingMessage,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191622),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Transaksi Anda diproses secara aman menggunakan enkripsi SSL.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF756E81),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCheckoutView(double totalBill, double serviceFee) {
    return Column(
      key: const ValueKey('checkout'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Color(0xFF0F766E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Portal Pembayaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 12, color: Color(0xFF047857)),
                  SizedBox(width: 4),
                  Text(
                    'Terenkripsi SSL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Tagihan Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Biaya Les'),
                  Text(
                    'Rp ${widget.item.totalAmount.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Biaya Layanan'),
                  Text(
                    'Rp ${serviceFee.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Rp ${totalBill.toInt()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7B2CBF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        // GoPay Select
        _buildMethodTile(
          id: 'gopay',
          icon: Icons.qr_code_scanner,
          title: 'GoPay / QRIS Dinamis',
          subtitle: 'Scan QR Code instan dari aplikasi e-wallet',
        ),
        const SizedBox(height: 10),
        // Virtual Account Select
        _buildMethodTile(
          id: 'bca_va',
          icon: Icons.account_balance,
          title: 'BCA Virtual Account',
          subtitle: 'Transfer via m-BCA / ATM',
        ),
        const SizedBox(height: 16),

        // Detail per metode
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(_selectedMethod),
            child: _selectedMethod == 'gopay'
                ? _buildGopayDetail()
                : _buildVaDetail(),
          ),
        ),
        const SizedBox(height: 24),

        // Tombol Bayar
        FilledButton(
          onPressed: _startPaymentProcess,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7B2CBF),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Bayar Sekarang',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B2CBF).withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B2CBF) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7B2CBF).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF7B2CBF) : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFF7B2CBF) : const Color(0xFF191622),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF756E81)),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF7B2CBF) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGopayDetail() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 72,
              color: Color(0xFF191622),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instruksi Pembayaran QRIS',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  '1. Pindai kode QR menggunakan aplikasi GoPay, OVO, Dana, atau LinkAja.\n'
                  '2. Status pembayaran akan terverifikasi secara otomatis setelah pembayaran sukses.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaDetail() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nomor Virtual Account BCA',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '88012893829103',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F766E),
                  letterSpacing: 1.1,
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA berhasil disalin!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 14, color: Color(0xFF0F766E)),
                      SizedBox(width: 4),
                      Text(
                        'Salin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Transfer tepat sejumlah total pembayaran via m-BCA atau ATM BCA. Pembayaran akan terverifikasi secara instan.',
            style: TextStyle(fontSize: 11, height: 1.3, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Future<void> _startPaymentProcess() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Menghubungi server Pembayaran...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() {
      _processingMessage = 'Memproses transaksi secara aman...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    Navigator.pop(context, _selectedMethod);
  }
}
