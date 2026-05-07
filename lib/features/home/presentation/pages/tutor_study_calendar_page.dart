import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorStudyCalendarPage extends ConsumerStatefulWidget {
  const TutorStudyCalendarPage({super.key});

  static const routeName = 'tutor-study-calendar';
  static const routePath = '/tutor/study-calendar';

  @override
  ConsumerState<TutorStudyCalendarPage> createState() =>
      _TutorStudyCalendarPageState();
}

class _TutorStudyCalendarPageState
    extends ConsumerState<TutorStudyCalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myTutorBookingsProvider);
    final sessionsAsync = ref.watch(myTutorSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender Mengajar')),
      body: bookingsAsync.when(
        loading: () => const AppLoadingState(
          message: 'Memuat kalender tutor...',
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
              message: 'Memuat sesi mengajar...',
              fullScreen: false,
            ),
            error: (error, _) => AppErrorState(
              message: 'Gagal memuat sesi mengajar.',
              detail: error.toString(),
              onRetry: () => ref.invalidate(myTutorSessionsStreamProvider),
            ),
            data: (sessions) {
              final bookingMap = <String, BookingItem>{
                for (final booking in bookings) booking.id: booking,
              };
              final selectedSessions = _onDay(sessions, _selectedDate);
              final daySummary = _buildDaySummary(selectedSessions);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: TutorUi.raisedCardDecoration(),
                    child: CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (value) {
                        setState(() {
                          _selectedDate = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CalendarDayHeader(
                    selectedDate: _selectedDate,
                    totalSessions: selectedSessions.length,
                    summary: daySummary,
                  ),
                  const SizedBox(height: 10),
                  if (selectedSessions.isEmpty)
                    const _CalendarEmptyCard()
                  else
                    ...selectedSessions.map((session) {
                      final booking = bookingMap[session.bookingId];
                      final subject = booking?.subject ?? 'Sesi Mengajar';
                      final studentName = booking?.studentName ?? 'Murid';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CalendarSessionCard(
                          session: session,
                          subject: subject,
                          studentName: studentName,
                          onTap: () => context.pushNamed(
                            TutorBookingsPage.routeName,
                            queryParameters: {
                              'bookingId': session.bookingId,
                              'sessionId': session.id,
                            },
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<BookingSession> _onDay(List<BookingSession> items, DateTime date) {
    return items.where((item) {
      final d = item.sessionStart;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
  }

  String _buildDaySummary(List<BookingSession> sessions) {
    final scheduled = sessions
        .where((session) => session.status == BookingSessionStatus.scheduled)
        .length;
    final waitingConfirm = sessions
        .where(
          (session) =>
              session.status == BookingSessionStatus.donePendingConfirmation,
        )
        .length;
    final disputes = sessions
        .where(
          (session) => session.status == BookingSessionStatus.disputedPending,
        )
        .length;

    final parts = <String>[];
    if (scheduled > 0) {
      parts.add('$scheduled terjadwal');
    }
    if (waitingConfirm > 0) {
      parts.add('$waitingConfirm menunggu konfirmasi');
    }
    if (disputes > 0) {
      parts.add('$disputes dispute');
    }

    if (parts.isEmpty) {
      return 'Semua sesi pada hari ini sudah berada di status final.';
    }
    return parts.join(' | ');
  }
}

class _CalendarDayHeader extends StatelessWidget {
  const _CalendarDayHeader({
    required this.selectedDate,
    required this.totalSessions,
    required this.summary,
  });

  final DateTime selectedDate;
  final int totalSessions;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TutorUi.softPanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(summary),
          const SizedBox(height: 10),
          _InfoPill(label: 'Total Sesi', value: '$totalSessions'),
        ],
      ),
    );
  }
}

class _CalendarSessionCard extends StatelessWidget {
  const _CalendarSessionCard({
    required this.session,
    required this.subject,
    required this.studentName,
    required this.onTap,
  });

  final BookingSession session;
  final String subject;
  final String studentName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [TutorUi.softShadow],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F0F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.school_outlined, color: Color(0xFF21425B)),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            TutorStatusBadge.session(status: session.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${session.sessionStart.hour.toString().padLeft(2, '0')}:${session.sessionStart.minute.toString().padLeft(2, '0')}'
                ' - ${session.sessionEnd.hour.toString().padLeft(2, '0')}:${session.sessionEnd.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: 4),
              Text('Murid: $studentName'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5ECF0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF21425B),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF21425B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEmptyCard extends StatelessWidget {
  const _CalendarEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      message: 'Tidak ada sesi di tanggal ini.',
      hint: 'Pilih tanggal lain atau cek booking aktif untuk melihat jadwal mengajar.',
      icon: Icons.event_available_outlined,
    );
  }
}
