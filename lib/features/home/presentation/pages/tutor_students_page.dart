import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
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
      appBar: AppBar(title: const Text('Murid Aktif')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'Gagal memuat booking tutor.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myTutorBookingsProvider),
        ),
        data: (bookings) {
          return sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: 'Gagal memuat sesi tutor.',
              detail: error.toString(),
              onRetry: () => ref.invalidate(myTutorSessionsProvider),
            ),
            data: (sessions) {
              final pendingHomework =
                  pendingHomeworkAsync.valueOrNull ?? const [];
              final now = DateTime.now();

              final activeBookings = bookings.where((booking) {
                final isActiveStatus =
                    booking.status == BookingStatus.awaitingPayment ||
                    booking.status == BookingStatus.paid;
                final inRange = !booking.packageEndDate.isBefore(
                  DateTime(now.year, now.month, now.day),
                );
                return isActiveStatus && inRange;
              }).toList();

              if (activeBookings.isEmpty) {
                return const _EmptyState(
                  message: 'Belum ada murid aktif saat ini.',
                );
              }

              final bookingMap = <String, BookingItem>{
                for (final booking in activeBookings) booking.id: booking,
              };

              final studentUids = activeBookings
                  .map((b) => b.studentUid)
                  .toSet()
                  .toList(growable: false);

              final studentModels =
                  studentUids.map((studentUid) {
                    final studentBookings = activeBookings
                        .where((b) => b.studentUid == studentUid)
                        .toList();
                    final displayName =
                        studentBookings.first.studentName.isNotEmpty
                        ? studentBookings.first.studentName
                        : studentUid;
                    final subjects = studentBookings
                        .map((b) => b.subject)
                        .toSet()
                        .toList();
                    final pendingHomeworkCount = pendingHomework
                        .where((record) => record.studentUid == studentUid)
                        .length;

                    final studentSessions = sessions.where((session) {
                      final booking = bookingMap[session.bookingId];
                      return booking != null &&
                          booking.studentUid == studentUid;
                    }).toList();

                    final nextCandidates =
                        studentSessions
                            .where(
                              (s) =>
                                  s.status == BookingSessionStatus.scheduled &&
                                  s.sessionStart.isAfter(now),
                            )
                            .toList()
                          ..sort(
                            (a, b) => a.sessionStart.compareTo(b.sessionStart),
                          );

                    final next = nextCandidates.isEmpty
                        ? null
                        : nextCandidates.first;
                    final primaryBookingId = studentBookings.first.id;

                    return (
                      studentName: displayName,
                      subjects: subjects,
                      pendingHomeworkCount: pendingHomeworkCount,
                      nextSession: next,
                      primaryBookingId: primaryBookingId,
                    );
                  }).toList()..sort(
                    (a, b) => b.pendingHomeworkCount.compareTo(
                      a.pendingHomeworkCount,
                    ),
                  );

              final limited = studentModels.take(2).toList(growable: false);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (studentModels.length > 2)
                    const _HintCard(
                      message:
                          'Catatan: sistem membatasi maksimal 2 murid aktif per tutor. Jika data lebih dari 2, kemungkinan berasal dari data lama.',
                    ),
                  ...limited.map(
                    (model) => _StudentCard(
                      studentName: model.studentName,
                      subjects: model.subjects,
                      pendingHomeworkCount: model.pendingHomeworkCount,
                      nextSession: model.nextSession,
                      onOpen: () => context.pushNamed(
                        TutorBookingsPage.routeName,
                        queryParameters: model.nextSession == null
                            ? {'bookingId': model.primaryBookingId}
                            : {
                                'bookingId': model.nextSession!.bookingId,
                                'sessionId': model.nextSession!.id,
                              },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.studentName,
    required this.subjects,
    required this.pendingHomeworkCount,
    required this.nextSession,
    required this.onOpen,
  });

  final String studentName;
  final List<String> subjects;
  final int pendingHomeworkCount;
  final BookingSession? nextSession;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final subtitleLines = <String>[];
    if (subjects.isNotEmpty) {
      subtitleLines.add('Mapel: ${subjects.take(3).join(', ')}');
    }
    if (nextSession != null) {
      subtitleLines.add(
        'Sesi berikutnya: ${nextSession!.sessionStart.day}/${nextSession!.sessionStart.month} '
        '${nextSession!.sessionStart.hour.toString().padLeft(2, '0')}:${nextSession!.sessionStart.minute.toString().padLeft(2, '0')}',
      );
    } else {
      subtitleLines.add('Sesi berikutnya: belum terjadwal');
    }
    subtitleLines.add('PR menunggu review: $pendingHomeworkCount');

    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          child: Text(studentName.isNotEmpty ? studentName[0] : '?'),
        ),
        title: Text(
          studentName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitleLines.join('\n')),
        isThreeLine: true,
        trailing: pendingHomeworkCount == 0
            ? const Icon(Icons.chevron_right)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pendingHomeworkCount',
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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
