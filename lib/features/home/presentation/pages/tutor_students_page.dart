import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorStudentsPage extends ConsumerWidget {
  const TutorStudentsPage({super.key});

  static const routeName = 'tutor-students';
  static const routePath = '/tutor/students';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myTutorBookingsProvider);
    final sessionsAsync = ref.watch(myTutorSessionsProvider);
    final pendingHomeworkAsync = ref.watch(myTutorPendingHomeworkProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Murid Aktif',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF4B176E),
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: bookingsAsync.when(
        loading: () => const AppLoadingState(
          message: 'Memuat murid aktif...',
          fullScreen: false,
        ),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat booking tutor.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myTutorBookingsProvider),
        ),
        data: (bookings) {
          return sessionsAsync.when(
            loading: () => const AppLoadingState(
              message: 'Memuat sesi tutor...',
              fullScreen: false,
            ),
            error: (error, _) => AppErrorState(
              message: 'Gagal memuat sesi tutor.',
              detail: error.toString(),
              onRetry: () => ref.invalidate(myTutorSessionsStreamProvider),
            ),
            data: (sessions) {
              final pendingHomework =
                  pendingHomeworkAsync.valueOrNull ??
                  const <SessionLearningRecord>[];
              final now = DateTime.now();

              final activeBookings = bookings
                  .where((booking) {
                    final isActiveStatus =
                        booking.status == BookingStatus.awaitingPayment ||
                        booking.status == BookingStatus.paid;
                    final inRange = !booking.packageEndDate.isBefore(
                      DateTime(now.year, now.month, now.day),
                    );
                    return isActiveStatus && inRange;
                  })
                  .toList(growable: false);

              if (activeBookings.isEmpty) {
                return const AppEmptyState(
                  message: 'Belum ada murid aktif saat ini.',
                  hint:
                      'Saat booking tutor berjalan, maksimal dua murid aktif akan muncul di sini.',
                  icon: FluentIcons.people_24_regular,
                );
              }

              final bookingMap = <String, BookingItem>{
                for (final booking in activeBookings) booking.id: booking,
              };

              final studentUids = activeBookings
                  .map((booking) => booking.studentUid)
                  .toSet()
                  .toList(growable: false);

              final studentModels =
                  studentUids.map((studentUid) {
                    final studentBookings = activeBookings
                        .where((booking) => booking.studentUid == studentUid)
                        .toList(growable: false);
                    final studentSessions = sessions
                        .where((session) {
                          final booking = bookingMap[session.bookingId];
                          return booking?.studentUid == studentUid;
                        })
                        .toList(growable: false);
                    final pendingRecords = pendingHomework
                        .where((record) => record.studentUid == studentUid)
                        .toList(growable: false);

                    final nextCandidates =
                        studentSessions
                            .where(
                              (session) =>
                                  session.status ==
                                      BookingSessionStatus.scheduled &&
                                  session.sessionStart.isAfter(now),
                            )
                            .toList()
                          ..sort(
                            (a, b) => a.sessionStart.compareTo(b.sessionStart),
                          );
                    final nextSession = nextCandidates.isEmpty
                        ? null
                        : nextCandidates.first;
                    final sessionTodayCount = studentSessions.where((session) {
                      return session.sessionStart.year == now.year &&
                          session.sessionStart.month == now.month &&
                          session.sessionStart.day == now.day;
                    }).length;
                    final confirmedCount = studentSessions.where((session) {
                      return session.status == BookingSessionStatus.confirmed ||
                          session.status ==
                              BookingSessionStatus.disputedResolved;
                    }).length;

                    return _TutorStudentModel(
                      studentUid: studentUid,
                      studentName: studentBookings.first.studentName,
                      subjects: studentBookings
                          .map((booking) => booking.subject)
                          .toSet()
                          .toList(growable: false),
                      activeBookings: studentBookings,
                      nextSession: nextSession,
                      sessionTodayCount: sessionTodayCount,
                      confirmedCount: confirmedCount,
                      totalSessionCount: studentSessions.length,
                      pendingHomeworkCount: pendingRecords.length,
                    );
                  }).toList()..sort(
                    (a, b) => b.pendingHomeworkCount.compareTo(
                      a.pendingHomeworkCount,
                    ),
                  );

              final totalPendingHomework = studentModels.fold<int>(
                0,
                (sum, student) => sum + student.pendingHomeworkCount,
              );
              final todaySessionTotal = studentModels.fold<int>(
                0,
                (sum, student) => sum + student.sessionTodayCount,
              );
              final shownStudents = studentModels
                  .take(2)
                  .toList(growable: false);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StudentsOverviewCard(
                    activeStudents: shownStudents.length,
                    totalPendingHomework: totalPendingHomework,
                    todaySessionTotal: todaySessionTotal,
                  ),
                  const SizedBox(height: 14),
                  if (studentModels.length > 2)
                    const _HintCard(
                      message:
                          'Catatan: sistem membatasi maksimal 2 murid aktif per tutor. Jika data lebih dari 2, kemungkinan berasal dari data lama.',
                    ),
                  ...shownStudents.map(
                    (model) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _StudentCard(
                        model: model,
                        onOpen: () => context.pushNamed(
                          TutorBookingsPage.routeName,
                          queryParameters: model.nextSession == null
                              ? {'bookingId': model.activeBookings.first.id}
                              : {
                                  'bookingId': model.nextSession!.bookingId,
                                  'sessionId': model.nextSession!.id,
                                },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

class _StudentsOverviewCard extends StatelessWidget {
  const _StudentsOverviewCard({
    required this.activeStudents,
    required this.totalPendingHomework,
    required this.todaySessionTotal,
  });

  final int activeStudents;
  final int totalPendingHomework;
  final int todaySessionTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: TutorUi.heroGradientPrimary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Roster Murid Aktif',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pantau murid yang sedang aktif belajar, sesi yang dekat, dan PR yang perlu kamu respons.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TopMetricPill(label: 'Murid', value: '$activeStudents'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopMetricPill(
                  label: 'PR Pending',
                  value: '$totalPendingHomework',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopMetricPill(
                  label: 'Sesi Hari Ini',
                  value: '$todaySessionTotal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopMetricPill extends StatelessWidget {
  const _TopMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends ConsumerWidget {
  const _StudentCard({required this.model, required this.onOpen});

  final _TutorStudentModel model;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(model.studentUid));
    final studentName = profileAsync.valueOrNull?.displayName ?? model.studentName;
    final displayStudentName = studentName.isEmpty ? '?' : studentName;
    final progressLabel = model.totalSessionCount == 0
        ? 'Belum ada progres sesi'
        : '${model.confirmedCount}/${model.totalSessionCount} sesi final';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TutorUi.raisedCardDecoration(
        radius: 24,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF2FF),
                child: Text(
                  displayStudentName != '?'
                      ? displayStudentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF4B176E),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayStudentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: model.subjects
                          .take(4)
                          .map((subject) => _TinyChip(label: subject))
                          .toList(),
                    ),
                  ],
                ),
              ),
              if (model.pendingHomeworkCount > 0)
                TutorStatusBadge.custom(
                  label: '${model.pendingHomeworkCount} PR',
                  background: TutorUi.rose,
                  foreground: const Color(0xFFB3261E),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoTile(title: 'Progress', value: progressLabel),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  title: 'Sesi Hari Ini',
                  value: '${model.sessionTodayCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoTile(
            title: 'Sesi Berikutnya',
            value: model.nextSession == null
                ? 'Belum ada sesi terdekat'
                : '${model.nextSession!.sessionStart.day}/${model.nextSession!.sessionStart.month} '
                      '${model.nextSession!.sessionStart.hour.toString().padLeft(2, '0')}:${model.nextSession!.sessionStart.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 10),
          _InfoTile(
            title: 'Paket Aktif',
            value: model.activeBookings
                .map(
                  (booking) =>
                      '${booking.subject} (${booking.packageMonths} bln)',
                )
                .join(', '),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka Detail Murid'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: TutorUi.softPanelDecoration(
        color: const Color(0xFFF7F9FF),
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF655C74)),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TutorUi.lavender,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4B176E),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _TutorStudentModel {
  const _TutorStudentModel({
    required this.studentUid,
    required this.studentName,
    required this.subjects,
    required this.activeBookings,
    required this.nextSession,
    required this.sessionTodayCount,
    required this.confirmedCount,
    required this.totalSessionCount,
    required this.pendingHomeworkCount,
  });

  final String studentUid;
  final String studentName;
  final List<String> subjects;
  final List<BookingItem> activeBookings;
  final BookingSession? nextSession;
  final int sessionTodayCount;
  final int confirmedCount;
  final int totalSessionCount;
  final int pendingHomeworkCount;
}
