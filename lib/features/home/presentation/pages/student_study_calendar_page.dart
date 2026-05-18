import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentStudyCalendarPage extends ConsumerStatefulWidget {
  const StudentStudyCalendarPage({super.key});

  static const routeName = 'student-study-calendar';
  static const routePath = '/student/study-calendar';

  @override
  ConsumerState<StudentStudyCalendarPage> createState() =>
      _StudentStudyCalendarPageState();
}

class _StudentStudyCalendarPageState
    extends ConsumerState<StudentStudyCalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingsSource = ref.watch(myStudentBookingsProvider);
    final sessionsSource = ref.watch(myStudentSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(FluentIcons.more_horizontal_24_regular),
          ),
        ],
      ),
      body: bookingsSource.when(
        loading: () => const AppLoadingState(
          message: 'Memuat kalender belajar...',
          fullScreen: false,
        ),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat jadwal belajar.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myStudentBookingsProvider),
          fullScreen: false,
        ),
        data: (bookings) {
          return sessionsSource.when(
            loading: () => const AppLoadingState(
              message: 'Memuat sesi belajar...',
              fullScreen: false,
            ),
            error: (error, _) => AppErrorState(
              message: 'Gagal memuat sesi belajar.',
              detail: error.toString(),
              onRetry: () => ref.invalidate(myStudentSessionsProvider),
              fullScreen: false,
            ),
            data: (sessions) {
              final bookingMap = {
                for (final booking in bookings) booking.id: booking,
              };
              final selectedItems = _onDay(sessions, _selectedDate);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          _getMonthName(_selectedDate.month),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF191622),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF191622)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Week 1',
                            style: TextStyle(
                              color: Color(0xFF4B176E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Horizontal Date Picker
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
                        final isSelected = date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4FD1C5) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isSelected ? const [
                                BoxShadow(
                                  color: Color(0x334FD1C5),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ] : null,
                              border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date.day.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : const Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getShortWeekday(date.weekday),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sessions List
                  Expanded(
                    child: selectedItems.isEmpty
                        ? const AppEmptyState(
                            message: 'Belum ada jadwal di tanggal ini.',
                            hint: 'Coba pilih tanggal lain.',
                            icon: Icons.event_busy_outlined,
                            fullScreen: false,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: selectedItems.length,
                            itemBuilder: (context, index) {
                              final session = selectedItems[index];
                              final booking = bookingMap[session.bookingId];
                              final subject = booking?.subject ?? 'Sesi Belajar';
                              final tutorName = booking?.tutorName ?? 'Tutor';
                              return _ClassCard(
                                subject: subject,
                                tutorName: tutorName,
                                startTime: session.sessionStart,
                                endTime: session.sessionEnd,
                                index: index,
                              );
                            },
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

  List<BookingSession> _onDay(List<BookingSession> items, DateTime date) {
    return items.where((item) {
      final d = item.sessionStart;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList()..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getShortWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.subject,
    required this.tutorName,
    required this.startTime,
    required this.endTime,
    required this.index,
  });

  final String subject;
  final String tutorName;
  final DateTime startTime;
  final DateTime endTime;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFF5F5), // Light Pink
      const Color(0xFFF0FFF4), // Light Green
      const Color(0xFFEBF8FF), // Light Blue
    ];
    final bgCol = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section (Image & Subject)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.asset(
                        'assets/images/math_3d_shapes.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Learn to know shape', // Default subtitle to match reference
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _MiniTag(
                            icon: FluentIcons.clock_12_regular,
                            text: '${endTime.difference(startTime).inMinutes} min',
                          ),
                          const SizedBox(width: 8),
                          const _MiniTag(
                            icon: FluentIcons.document_16_regular,
                            text: '1 Assignment',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom section (Tutor & Join Button)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    tutorName.isNotEmpty ? tutorName[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tutor by:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                      ),
                      Text(
                        tutorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF), // Brand purple
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  child: const Text('Join Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF4A5568)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }
}
