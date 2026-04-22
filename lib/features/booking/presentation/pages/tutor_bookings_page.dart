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

class TutorBookingsPage extends ConsumerStatefulWidget {
  const TutorBookingsPage({super.key});

  static const routeName = 'tutor-bookings';
  static const routePath = '/tutor/bookings';

  @override
  ConsumerState<TutorBookingsPage> createState() => _TutorBookingsPageState();
}

class _TutorBookingsPageState extends ConsumerState<TutorBookingsPage> {
  final Map<String, GlobalKey> _sessionAnchorKeys = <String, GlobalKey>{};
  String? _lastAutoScrolledSessionId;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myTutorBookingsProvider);
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
      appBar: AppBar(title: const Text('Jadwal Saya (Tutor)')),
      body: bookingsAsync.when(
        data: (items) {
          final now = DateTime.now();
          final requests =
              items
                  .where((item) => item.status == BookingStatus.pending)
                  .toList()
                ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
          _bringFocusedBookingToFront(requests, focusedBookingId);
          final active =
              items
                  .where((item) => isTutorActiveBooking(item, now: now))
                  .toList()
                ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
          _bringFocusedBookingToFront(active, focusedBookingId);
          final history =
              items
                  .where((item) => isTutorHistoryBooking(item, now: now))
                  .toList()
                ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));
          _bringFocusedBookingToFront(history, focusedBookingId);
          final initialTab = active.any((item) => item.id == focusedBookingId)
              ? 1
              : history.any((item) => item.id == focusedBookingId)
              ? 2
              : 0;

          _scheduleAutoScrollToSession(
            focusedSessionId: focusedSessionId,
            focusedSessionKey: focusedSessionKey,
          );

          return DefaultTabController(
            length: 3,
            initialIndex: initialTab,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Permintaan'),
                    Tab(text: 'Jadwal Aktif'),
                    Tab(text: 'Riwayat'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TutorBookingList(
                        items: requests,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada permintaan booking baru.',
                        onRespond: _handleRespond,
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                      _TutorBookingList(
                        items: active,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada jadwal aktif.',
                        onRespond: _handleRespond,
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                      _TutorBookingList(
                        items: history,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada riwayat kelas.',
                        onRespond: _handleRespond,
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
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(height: 8),
                const Text('Gagal memuat jadwal tutor.'),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(myTutorBookingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
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

  Future<void> _handleRespond({
    required String bookingId,
    required BookingStatus status,
    required String successMessage,
  }) async {
    try {
      await ref
          .read(bookingControllerProvider)
          .respondBooking(bookingId: bookingId, status: status);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aksi booking gagal: ${error.toString()}')),
      );
    }
  }
}

class _TutorBookingList extends ConsumerWidget {
  const _TutorBookingList({
    required this.items,
    required this.isLoading,
    required this.emptyMessage,
    required this.onRespond,
    required this.focusedSessionId,
    required this.focusedSessionKey,
  });

  final List<BookingItem> items;
  final bool isLoading;
  final String emptyMessage;
  final String? focusedSessionId;
  final GlobalKey? focusedSessionKey;
  final Future<void> Function({
    required String bookingId,
    required BookingStatus status,
    required String successMessage,
  })
  onRespond;

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

  Future<void> _showLearningRecordDialog({
    required BuildContext context,
    required WidgetRef ref,
    required BookingItem booking,
    required String sessionId,
    SessionLearningRecord? existing,
  }) async {
    final summaryController = TextEditingController(
      text: existing?.materialSummary ?? '',
    );
    final notesController = TextEditingController(
      text: existing?.materialNotes ?? '',
    );
    final homeworkTitleController = TextEditingController(
      text: existing?.homeworkTitle ?? '',
    );
    final homeworkDescController = TextEditingController(
      text: existing?.homeworkDescription ?? '',
    );

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Materi & PR Sesi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(
                  labelText: 'Ringkasan materi',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Catatan tutor'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: homeworkTitleController,
                decoration: const InputDecoration(
                  labelText: 'Judul PR (opsional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: homeworkDescController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi PR (opsional)',
                ),
              ),
            ],
          ),
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
      ),
    );

    if (submit != true) {
      summaryController.dispose();
      notesController.dispose();
      homeworkTitleController.dispose();
      homeworkDescController.dispose();
      return;
    }

    await ref
        .read(bookingControllerProvider)
        .saveTutorLearningRecord(
          bookingId: booking.id,
          sessionId: sessionId,
          studentUid: booking.studentUid,
          materialSummary: summaryController.text,
          materialNotes: notesController.text,
          homeworkTitle: homeworkTitleController.text,
          homeworkDescription: homeworkDescController.text,
        );
    summaryController.dispose();
    notesController.dispose();
    homeworkTitleController.dispose();
    homeworkDescController.dispose();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Materi & PR berhasil disimpan.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final sessionsAsync = ref.watch(bookingSessionsProvider(item.id));
        final requestsAsync = ref.watch(sessionChangeRequestsProvider(item.id));
        final learningAsync = ref.watch(
          sessionLearningRecordsProvider(item.id),
        );
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
                  'Murid: ${item.studentName.isEmpty ? item.studentUid : item.studentName}',
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
                if (item.message.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Catatan: ${item.message}'),
                ],
                const SizedBox(height: 10),
                Text(
                  'Riwayat Pertemuan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                sessionsAsync.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return const Text('Belum ada sesi terjadwal.');
                    }
                    final shortlist = _selectDisplayedSessions(
                      sessions,
                      focusedSessionId,
                    );
                    return Column(
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
                        final canMarkDone =
                            session.status == BookingSessionStatus.scheduled &&
                            session.sessionEnd.isBefore(DateTime.now());
                        final canRequestChange =
                            request == null &&
                            session.status == BookingSessionStatus.scheduled &&
                            session.sessionStart.isAfter(DateTime.now());
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          key: isFocusedSession ? focusedSessionKey : null,
                          margin: const EdgeInsets.only(bottom: 8),
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
                              Builder(
                                builder: (context) {
                                  if (learningRecord == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (learningRecord.materialSummary
                                            .trim()
                                            .isNotEmpty)
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
                                          Text(
                                            'PR: ${learningRecord.homeworkTitle}',
                                          ),
                                          Text(
                                            'Status PR: ${learningRecord.homeworkStatus.label}',
                                          ),
                                          if (learningRecord.studentSubmission
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              'Jawaban murid: ${learningRecord.studentSubmission}',
                                            ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
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
                                          onPressed: isLoading
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
                                          onPressed: isLoading
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
                              if (canMarkDone) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            try {
                                              await ref
                                                  .read(
                                                    bookingControllerProvider,
                                                  )
                                                  .markSessionDoneByTutor(
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
                                                    'Pertemuan ditandai selesai. Menunggu konfirmasi murid.',
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
                                                    'Gagal update sesi: ${error.toString()}',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    child: const Text('Tandai Sesi Selesai'),
                                  ),
                                ),
                              ],
                              if (session.status ==
                                  BookingSessionStatus.disputedPending) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            try {
                                              await ref
                                                  .read(
                                                    bookingControllerProvider,
                                                  )
                                                  .resolveDisputeByTutor(
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
                                                    'Dispute ditutup. Status sesi diperbarui.',
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
                                                    'Gagal menutup dispute: ${error.toString()}',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.verified_outlined),
                                    label: const Text('Tutup Dispute'),
                                  ),
                                ),
                              ],
                              if (canRequestChange) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: isLoading
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
                                        onPressed: isLoading
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : () => _showLearningRecordDialog(
                                              context: context,
                                              ref: ref,
                                              booking: item,
                                              sessionId: session.id,
                                              existing: learningRecord,
                                            ),
                                      icon: const Icon(
                                        Icons.menu_book_outlined,
                                      ),
                                      label: const Text('Materi & PR'),
                                    ),
                                  ),
                                  if (learningRecord != null &&
                                      learningRecord.homeworkStatus ==
                                          HomeworkStatus.submitted) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton.tonalIcon(
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                await ref
                                                    .read(
                                                      bookingControllerProvider,
                                                    )
                                                    .markHomeworkReviewed(
                                                      sessionId: session.id,
                                                    );
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'PR ditandai sudah direview.',
                                                    ),
                                                  ),
                                                );
                                              },
                                        icon: const Icon(Icons.task_alt),
                                        label: const Text('Review PR'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text('Gagal memuat sesi: $error'),
                ),
                const SizedBox(height: 10),
                if (item.status == BookingStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => onRespond(
                                  bookingId: item.id,
                                  status: BookingStatus.rejected,
                                  successMessage: 'Booking ditolak.',
                                ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () => onRespond(
                                  bookingId: item.id,
                                  status: BookingStatus.awaitingPayment,
                                  successMessage:
                                      'Booking diterima. Menunggu pembayaran murid.',
                                ),
                          child: const Text('Terima'),
                        ),
                      ),
                    ],
                  )
                else if (item.status == BookingStatus.paid)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () => onRespond(
                                  bookingId: item.id,
                                  status: BookingStatus.completed,
                                  successMessage: 'Kelas ditandai selesai.',
                                ),
                          child: const Text('Tandai Selesai'),
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
      },
    );
  }
}
