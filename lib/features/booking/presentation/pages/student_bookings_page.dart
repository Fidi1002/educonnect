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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RetryState(
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

    // Wait until widgets mount, then smooth-scroll the focused session into view.
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
      return _EmptyState(message: emptyMessage);
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
                  child: Text(
                    item.subject,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(label: Text(item.status.label)),
              ],
            ),
            Text(
              'Tutor: ${item.tutorName.isEmpty ? item.tutorUid : item.tutorName}',
            ),
            Text(
              'Paket: ${item.packageMonths} bulan • ${item.sessionsPerWeek}x/minggu',
            ),
            Text(
              'Periode: ${item.packageStartDate.day}/${item.packageStartDate.month}/${item.packageStartDate.year}'
              ' - ${item.packageEndDate.day}/${item.packageEndDate.month}/${item.packageEndDate.year}',
            ),
            if (item.weeklySchedule.isNotEmpty)
              Text(
                'Jadwal tetap: ${item.weeklySchedule.map((slot) => '${slot.weekdayLabel} ${slot.timeLabel}').join(' • ')}',
              ),
            Text(
              'Jadwal: ${item.sessionStart.day}/${item.sessionStart.month}/${item.sessionStart.year} '
              '${item.sessionStart.hour.toString().padLeft(2, '0')}:${item.sessionStart.minute.toString().padLeft(2, '0')}',
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
                  return const Text('Belum ada data pertemuan.');
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
                            session.status == BookingSessionStatus.scheduled &&
                            session.sessionStart.isAfter(DateTime.now()) &&
                            session.sessionStart.isBefore(
                              DateTime.now().add(const Duration(hours: 24)),
                            );
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
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${session.status.label}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (session.studentPresenceConfirmedAt != null)
                                  Text(
                                    'Hadir dikonfirmasi '
                                    '${session.studentPresenceConfirmedAt!.hour.toString().padLeft(2, '0')}:'
                                    '${session.studentPresenceConfirmedAt!.minute.toString().padLeft(2, '0')}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                if (learningRecord != null) ...[
                                  const SizedBox(height: 8),
                                  if (learningRecord.hasMaterial)
                                    Text(
                                      'Materi: ${learningRecord.materialSummary}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (learningRecord.materialNotes
                                      .trim()
                                      .isNotEmpty)
                                    Text(
                                      'Catatan: ${learningRecord.materialNotes}',
                                    ),
                                  if (learningRecord.hasHomework) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'PR: ${learningRecord.homeworkTitle}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (learningRecord.homeworkDescription
                                        .trim()
                                        .isNotEmpty)
                                      Text(learningRecord.homeworkDescription),
                                    Text(
                                      'Status PR: ${learningRecord.homeworkStatus.label}',
                                    ),
                                    if (learningRecord.studentSubmission
                                        .trim()
                                        .isNotEmpty)
                                      Text(
                                        'Jawaban saya: ${learningRecord.studentSubmission}',
                                      ),
                                  ],
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
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
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
                                                    'Kehadiran berhasil dikonfirmasi.',
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
                          child: Row(
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
                        ),
                      ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Gagal memuat sesi: $error'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
