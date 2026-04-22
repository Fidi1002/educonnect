import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Gagal memuat booking: $error')),
        data: (bookings) {
          return sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Gagal memuat sesi: $error')),
            data: (sessions) {
              final bookingMap = <String, BookingItem>{
                for (final booking in bookings) booking.id: booking,
              };
              final selectedSessions = _onDay(sessions, _selectedDate);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
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
                  Text(
                    'Jadwal ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (selectedSessions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Tidak ada sesi di tanggal ini.'),
                      ),
                    )
                  else
                    ...selectedSessions.map((session) {
                      final booking = bookingMap[session.bookingId];
                      final subject = booking?.subject ?? 'Sesi Mengajar';
                      final studentName = booking?.studentName ?? 'Murid';
                      final statusStyle = _sessionStatusStyle(session.status);
                      return Card(
                        child: ListTile(
                          onTap: () => context.pushNamed(
                            TutorBookingsPage.routeName,
                            queryParameters: {
                              'bookingId': session.bookingId,
                              'sessionId': session.id,
                            },
                          ),
                          title: Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${session.sessionStart.hour.toString().padLeft(2, '0')}:${session.sessionStart.minute.toString().padLeft(2, '0')}'
                                ' - ${session.sessionEnd.hour.toString().padLeft(2, '0')}:${session.sessionEnd.minute.toString().padLeft(2, '0')}',
                              ),
                              Text('Murid: $studentName'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusStyle.$2,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusStyle.$1,
                                  style: TextStyle(
                                    color: statusStyle.$3,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
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

  (String, Color, Color) _sessionStatusStyle(BookingSessionStatus status) {
    switch (status) {
      case BookingSessionStatus.scheduled:
      case BookingSessionStatus.rescheduled:
        return ('Terjadwal', const Color(0xFFE8F1FF), const Color(0xFF174EA6));
      case BookingSessionStatus.confirmed:
      case BookingSessionStatus.disputedResolved:
        return (
          'Terkonfirmasi',
          const Color(0xFFE8F7EE),
          const Color(0xFF1E7E34),
        );
      case BookingSessionStatus.donePendingConfirmation:
        return (
          'Menunggu Konfirmasi',
          const Color(0xFFFFF4E5),
          const Color(0xFF9A5D00),
        );
      case BookingSessionStatus.disputedPending:
        return ('Dispute', const Color(0xFFFFEBEE), const Color(0xFFB3261E));
      case BookingSessionStatus.cancelledByStudent:
      case BookingSessionStatus.cancelledByTutor:
      case BookingSessionStatus.cancelledEarly:
      case BookingSessionStatus.cancelledLate:
      case BookingSessionStatus.studentNoShow:
      case BookingSessionStatus.tutorNoShow:
        return ('Dibatalkan', const Color(0xFFF3F4F6), const Color(0xFF4B5563));
    }
  }
}
