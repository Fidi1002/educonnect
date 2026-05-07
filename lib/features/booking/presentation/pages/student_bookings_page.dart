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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    Future<void>.microtask(
      () => ref.read(bookingControllerProvider).processSmartSessionReminders(),
    );
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
              items.where((item) => isStudentUpcomingBooking(item, now: now)).toList()
                ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
          _bringFocusedBookingToFront(upcoming, focusedBookingId);
          final history =
              items.where((item) => !isStudentUpcomingBooking(item, now: now)).toList()
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
                const TabBar(
                  tabs: [
                    Tab(text: 'Akan Datang'),
                    Tab(text: 'Riwayat'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _BookingList(
                        items: upcoming,
                        isLoading: isLoading,
                        emptyMessage:
                            'Belum ada jadwal kelas aktif. Mulai booking tutor dulu ya.',
                        onPayDummy: (bookingId) => _payDummy(bookingId),
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                      _BookingList(
                        items: history,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada riwayat booking.',
                        onPayDummy: (bookingId) => _payDummy(bookingId),
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
        loading: () =>
            const AppLoadingState(message: 'Memuat jadwal belajar...', fullScreen: false),
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

  Future<void> _payDummy(String bookingId) async {
    try {
      await ref
          .read(bookingControllerProvider)
          .payDummyBooking(bookingId: bookingId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran dummy berhasil. Status lunas.'),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran gagal: ${error.toString()}')),
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
    final active = allItems.where((item) => item.status == BookingStatus.paid).length;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F0FE), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE7D8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetricPill(
                  label: 'Aktif',
                  value: '$active',
                  accent: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetricPill(
                  label: 'Riwayat',
                  value: '${historyItems.length}',
                  accent: const Color(0xFF9A6700),
                ),
              ),
            ],
          ),
          if (awaitingPayment > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5DD),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF9A6700),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$awaitingPayment booking masih menunggu pembayaran agar jadwal aktif penuh.',
                      style: const TextStyle(
                        color: Color(0xFF6F5200),
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
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF736A81),
              fontWeight: FontWeight.w600,
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
    required this.onPayDummy,
    required this.focusedSessionId,
    required this.focusedSessionKey,
  });

  final List<BookingItem> items;
  final bool isLoading;
  final String emptyMessage;
  final ValueChanged<String> onPayDummy;
  final String? focusedSessionId;
  final GlobalKey? focusedSessionKey;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(
        message: emptyMessage,
        hint: 'Saat booking aktif atau riwayat kelas tersedia, semuanya akan muncul di sini.',
        icon: Icons.menu_book_outlined,
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
          onPayDummy: item.status == BookingStatus.awaitingPayment
              ? () => onPayDummy(item.id)
              : null,
          focusedSessionId: focusedSessionId,
          focusedSessionKey: focusedSessionKey,
        );
      },
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({
    required this.item,
    required this.paymentLoading,
    this.onPayDummy,
    this.focusedSessionId,
    this.focusedSessionKey,
  });

  final BookingItem item;
  final bool paymentLoading;
  final VoidCallback? onPayDummy;
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tutor: ${item.tutorName.isEmpty ? item.tutorUid : item.tutorName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF776F84),
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
                ),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label:
                      '${item.sessionStart.day}/${item.sessionStart.month}/${item.sessionStart.year} ${item.sessionStart.hour.toString().padLeft(2, '0')}:${item.sessionStart.minute.toString().padLeft(2, '0')}',
                ),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label: item.paidAt == null
                      ? 'Menunggu pembayaran'
                      : 'Pembayaran tuntas',
                  accent: item.paidAt == null
                      ? const Color(0xFF9A6700)
                      : const Color(0xFF0F766E),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Periode: ${item.packageStartDate.day}/${item.packageStartDate.month}/${item.packageStartDate.year}'
              ' - ${item.packageEndDate.day}/${item.packageEndDate.month}/${item.packageEndDate.year}',
            ),
            if (item.weeklySchedule.isNotEmpty)
              Text(
                'Jadwal tetap: ${item.weeklySchedule.map((slot) => '${slot.weekdayLabel} ${slot.timeLabel}').join(' • ')}',
              ),
            Text('Durasi: ${item.durationMinutes} menit'),
            Text('Biaya: Rp ${item.totalAmount}'),
            if (item.paidAt != null)
              Text(
                'Dibayar: ${item.paidAt!.day}/${item.paidAt!.month}/${item.paidAt!.year} '
                '${item.paidAt!.hour.toString().padLeft(2, '0')}:${item.paidAt!.minute.toString().padLeft(2, '0')}',
              ),
            if (item.message.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Catatan: ${item.message}'),
            ],
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
                    hint: 'Sesi akan tampil setelah booking diproses dan jadwal terbentuk.',
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
                  children: shortlist.map((session) {
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
                        session.status == BookingSessionStatus.scheduled &&
                        session.sessionStart.isAfter(DateTime.now()) &&
                        session.sessionStart.isBefore(
                          DateTime.now().add(const Duration(hours: 24)),
                        );
                    final canMarkTutorNoShow =
                        session.status == BookingSessionStatus.scheduled &&
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
                              style: const TextStyle(fontWeight: FontWeight.w700),
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
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            if (learningRecord != null &&
                                (learningRecord.hasMaterial ||
                                    learningRecord.hasHomework)) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Learning Journal',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.copyWith(
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
                                          learningRecord.homeworkDescription,
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
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Sesi ditandai dispute. Tutor akan ditinjau.',
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
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Gagal konfirmasi sesi: ${error.toString()}',
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
                                                .markTutorNoShow(session.id);
                                            if (!context.mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Sesi ditandai tutor tidak hadir.',
                                                ),
                                              ),
                                            );
                                          } on Exception catch (error) {
                                            if (!context.mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Gagal menandai no-show: ${error.toString()}',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.person_off_outlined),
                                  label: const Text('Tutor Tidak Hadir'),
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
                                      child: const Text('Ajukan Reschedule'),
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
                                              .read(bookingControllerProvider)
                                              .confirmSessionPresence(session.id);
                                          if (!context.mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Kehadiran berhasil dikonfirmasi.',
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.how_to_reg_outlined),
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
                                  icon: const Icon(Icons.assignment_turned_in),
                                  label: const Text('Kumpulkan PR'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList()
                    ..insert(
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
                child: LinearProgressIndicator(),
              ),
              error: (error, _) => AppErrorState(
                message: 'Gagal memuat sesi belajar.',
                detail: error.toString(),
                fullScreen: false,
              ),
            ),
            const SizedBox(height: 10),
            if (onPayDummy != null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: paymentLoading ? null : onPayDummy,
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(
                        paymentLoading
                            ? 'Memproses...'
                            : 'Bayar Sekarang (Dummy)',
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
                      icon: const Icon(Icons.chat_bubble_outline),
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
                icon: const Icon(Icons.chat_bubble_outline),
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

  Future<void> _showCancelRequestDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String sessionId,
  }) async {
    final reasonController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajukan Pembatalan'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Alasan pembatalan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
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

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajukan Reschedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      if (date == null || !context.mounted) {
                        return;
                      }
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 16, minute: 0),
                      );
                      if (time == null || !context.mounted) {
                        return;
                      }
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
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(
                      selectedDateTime == null
                          ? 'Pilih jadwal baru'
                          : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} '
                                '${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Alasan'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: selectedDateTime == null
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Kirim'),
                ),
              ],
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
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kumpulkan PR'),
        content: TextField(
          controller: submissionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Jawaban / link tugas',
            hintText: 'Tulis jawaban atau tempel link tugasmu di sini',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PR berhasil dikumpulkan.')));
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
      BookingStatus.paid => (
        const Color(0xFFE7F8F1),
        const Color(0xFF0F766E),
      ),
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
      BookingSessionStatus.studentNoShow || BookingSessionStatus.tutorNoShow => (
        const Color(0xFFFCE7E7),
        const Color(0xFF9F1239),
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
