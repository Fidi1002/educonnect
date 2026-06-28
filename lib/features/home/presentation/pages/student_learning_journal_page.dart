import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _JournalHomeworkFilter { all, pending, submitted, reviewed, noHomework }

enum _JournalSortOrder { newestFirst, oldestFirst }

class StudentLearningJournalPage extends ConsumerStatefulWidget {
  const StudentLearningJournalPage({super.key});

  static const routeName = 'student-learning-journal';
  static const routePath = '/student/learning-journal';

  @override
  ConsumerState<StudentLearningJournalPage> createState() =>
      _StudentLearningJournalPageState();
}

class _StudentLearningJournalPageState
    extends ConsumerState<StudentLearningJournalPage> {
  String _selectedSubject = 'Semua';
  _JournalHomeworkFilter _homeworkFilter = _JournalHomeworkFilter.all;
  _JournalSortOrder _sortOrder = _JournalSortOrder.newestFirst;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myStudentBookingsProvider);
    final sessionsAsync = ref.watch(myStudentSessionsProvider);
    final recordsAsync = ref.watch(myStudentLearningRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: bookingsAsync.when(
        data: (bookings) => sessionsAsync.when(
          data: (sessions) => recordsAsync.when(
            data: (records) {
              final data = _StudentJournalData.fromData(
                bookings: bookings,
                sessions: sessions,
                records: records,
              );
              if (data.entries.isEmpty) {
                return const _JournalEmptyState();
              }

              final visibleEntries = data.filteredEntries(
                subject: _selectedSubject,
                homeworkFilter: _homeworkFilter,
                sortOrder: _sortOrder,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    'Jurnal Belajar',
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
                  _JournalHero(data: data),
                  const SizedBox(height: 14),
                  _JournalHomeworkStats(data: data),
                  const SizedBox(height: 14),
                  _JournalSubjectSection(data: data),
                  const SizedBox(height: 18),
                  _JournalFilters(
                    subjects: data.availableSubjects,
                    selectedSubject: _selectedSubject,
                    homeworkFilter: _homeworkFilter,
                    sortOrder: _sortOrder,
                    onSubjectChanged: (value) {
                      setState(() => _selectedSubject = value);
                    },
                    onHomeworkFilterChanged: (value) {
                      setState(() => _homeworkFilter = value);
                    },
                    onSortOrderChanged: (value) {
                      setState(() => _sortOrder = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Riwayat Belajar',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${visibleEntries.length} sesi',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7F778C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (visibleEntries.isEmpty)
                    const _JournalFilterEmptyState()
                  else
                    ...visibleEntries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _JournalEntryCard(entry: entry),
                      ),
                    ),
                ],
              );
            },
            loading: () => const AppLoadingState(
              message: 'Memuat catatan belajar...',
              fullScreen: false,
            ),
            error: (error, _) => AppErrorState(
              message: 'Gagal memuat learning journal.',
              detail: error.toString(),
              fullScreen: false,
            ),
          ),
          loading: () => const AppLoadingState(
            message: 'Memuat sesi belajar...',
            fullScreen: false,
          ),
          error: (error, _) => AppErrorState(
            message: 'Gagal memuat sesi belajar.',
            detail: error.toString(),
            fullScreen: false,
          ),
        ),
        loading: () =>
            const AppLoadingState(message: 'Memuat learning journal...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat learning journal.',
          detail: error.toString(),
          fullScreen: true,
        ),
      ),
    );
  }
}

class _JournalHero extends StatelessWidget {
  const _JournalHero({required this.data});

  final _StudentJournalData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Progress Belajar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.timeline_rounded,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${data.completedSessions}/${data.totalSessions} sesi selesai',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.pendingHomeworkCount} PR masih pending • ${data.totalStudyHours} jam belajar tercatat',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Materi dicatat',
                  value: '${data.materialCount}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Tutor aktif',
                  value: '${data.activeTutorCount}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Mapel',
                  value: '${data.subjects.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _JournalSubjectSection extends StatelessWidget {
  const _JournalSubjectSection({required this.data});

  final _StudentJournalData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan per Mapel',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.subjects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final subject = data.subjects[index];
              return Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFC9D8F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF241A33),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${subject.completedSessions}/${subject.totalSessions} sesi selesai',
                      style: const TextStyle(color: Color(0xFF6E667B)),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: subject.totalSessions == 0
                            ? 0
                            : subject.completedSessions / subject.totalSessions,
                        backgroundColor: const Color(0xFFDCE8FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4B176E),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${subject.pendingHomeworkCount} PR pending',
                      style: const TextStyle(
                        color: Color(0xFF4B176E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _JournalHomeworkStats extends StatelessWidget {
  const _JournalHomeworkStats({required this.data});

  final _StudentJournalData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeworkStatCard(
            label: 'PR Pending',
            value: '${data.pendingHomeworkCount}',
            accent: const Color(0xFF9A6700),
            background: const Color(0xFFFFF7E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HomeworkStatCard(
            label: 'Submitted',
            value: '${data.submittedHomeworkCount}',
            accent: const Color(0xFF0369A1),
            background: const Color(0xFFF0F9FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HomeworkStatCard(
            label: 'Reviewed',
            value: '${data.reviewedHomeworkCount}',
            accent: const Color(0xFF0F766E),
            background: const Color(0xFFECFDF5),
          ),
        ),
      ],
    );
  }
}

class _HomeworkStatCard extends StatelessWidget {
  const _HomeworkStatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6F667B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalFilters extends StatelessWidget {
  const _JournalFilters({
    required this.subjects,
    required this.selectedSubject,
    required this.homeworkFilter,
    required this.sortOrder,
    required this.onSubjectChanged,
    required this.onHomeworkFilterChanged,
    required this.onSortOrderChanged,
  });

  final List<String> subjects;
  final String selectedSubject;
  final _JournalHomeworkFilter homeworkFilter;
  final _JournalSortOrder sortOrder;
  final ValueChanged<String> onSubjectChanged;
  final ValueChanged<_JournalHomeworkFilter> onHomeworkFilterChanged;
  final ValueChanged<_JournalSortOrder> onSortOrderChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC9D8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Jurnal',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'Mapel',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((subject) {
              return ChoiceChip(
                label: Text(subject),
                selected: selectedSubject == subject,
                onSelected: (_) => onSubjectChanged(subject),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Status PR',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _JournalHomeworkFilter.values.map((filter) {
              return ChoiceChip(
                label: Text(_homeworkFilterLabel(filter)),
                selected: homeworkFilter == filter,
                onSelected: (_) => onHomeworkFilterChanged(filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Urutan Timeline',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_JournalSortOrder>(
            segments: const [
              ButtonSegment(
                value: _JournalSortOrder.newestFirst,
                label: Text('Terbaru'),
                icon: Icon(Icons.south_rounded),
              ),
              ButtonSegment(
                value: _JournalSortOrder.oldestFirst,
                label: Text('Terlama'),
                icon: Icon(Icons.north_rounded),
              ),
            ],
            selected: {sortOrder},
            onSelectionChanged: (selection) =>
                onSortOrderChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry});

  final _JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final record = entry.record;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.pushNamed(
        StudentBookingsPage.routeName,
        queryParameters: {
          'bookingId': entry.booking.id,
          'sessionId': entry.session.id,
        },
      ),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.booking.subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.booking.tutorName} • ${_formatSessionDate(entry.session.sessionStart)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7D758A),
                        ),
                      ),
                    ],
                  ),
                ),
                _SessionBadge(status: entry.session.status),
              ],
            ),
            if (record != null && record.hasMaterial) ...[
              const SizedBox(height: 12),
              _JournalBlock(
                icon: FluentIcons.book_24_regular,
                title: 'Materi',
                content: record.materialSummary,
                note: record.materialNotes.trim().isEmpty
                    ? null
                    : record.materialNotes,
              ),
            ],
            if (record != null && record.hasHomework) ...[
              const SizedBox(height: 10),
              _JournalBlock(
                icon: Icons.assignment_outlined,
                title: 'PR',
                content: record.homeworkTitle.trim().isEmpty
                    ? 'PR diberikan tutor'
                    : record.homeworkTitle,
                note: [
                  if (record.homeworkDescription.trim().isNotEmpty)
                    record.homeworkDescription,
                  'Status PR: ${record.homeworkStatus.label}',
                  if (record.studentSubmission.trim().isNotEmpty)
                    'Jawaban saya: ${record.studentSubmission}',
                  if (record.homeworkStatus == HomeworkStatus.reviewed) ...[
                    if (record.homeworkGrade != null)
                      'Nilai PR: ${record.homeworkGrade}/100 🌟',
                    if (record.tutorFeedback.trim().isNotEmpty)
                      'Catatan Tutor: ${record.tutorFeedback}',
                  ],
                ].join('\n'),
                accent: const Color(0xFF9A6700),
                background: const Color(0xFFFFF8E8),
              ),
            ],
            if (record == null ||
                (!record.hasMaterial && !record.hasHomework)) ...[
              const SizedBox(height: 12),
              Text(
                'Sesi ini belum memiliki catatan materi lengkap, tapi tetap tercatat di riwayat belajarmu.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7D758A)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JournalBlock extends StatelessWidget {
  const _JournalBlock({
    required this.icon,
    required this.title,
    required this.content,
    this.note,
    this.accent = const Color(0xFF4B176E),
    this.background = const Color(0xFFF7F9FF),
  });

  final IconData icon;
  final String title;
  final String content;
  final String? note;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF241A33),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (note != null && note!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F667B)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionBadge extends StatelessWidget {
  const _SessionBadge({required this.status});

  final BookingSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      BookingSessionStatus.confirmed => (
        const Color(0xFFE8F8EF),
        const Color(0xFF0F766E),
      ),
      BookingSessionStatus.donePendingConfirmation => (
        const Color(0xFFFFF4D8),
        const Color(0xFF9A6700),
      ),
      BookingSessionStatus.disputedResolved => (
        const Color(0xFFEDE9FE),
        const Color(0xFF6D28D9),
      ),
      BookingSessionStatus.disputedPending => (
        const Color(0xFFFCE7E7),
        const Color(0xFFB91C1C),
      ),
      BookingSessionStatus.studentNoShow || BookingSessionStatus.tutorNoShow =>
        (const Color(0xFFFCE7E7), const Color(0xFF9F1239)),
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
      BookingSessionStatus.scheduled => (
        const Color(0xFFE7ECFF),
        const Color(0xFF3730A3),
      ),
      BookingSessionStatus.inProgress => (
        const Color(0xFFE1F5FE),
        const Color(0xFF0277BD),
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

class _JournalEmptyState extends StatelessWidget {
  const _JournalEmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      message: 'Belum ada jurnal belajar.',
      hint:
          'Setelah sesi berjalan dan tutor mengisi materi atau PR, riwayat progres belajarmu akan muncul di sini.',
      icon: Icons.auto_stories_outlined,
      fullScreen: true,
    );
  }
}

class _JournalFilterEmptyState extends StatelessWidget {
  const _JournalFilterEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DFF1)),
      ),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_outlined, color: Colors.grey.shade600),
          const SizedBox(height: 10),
          const Text(
            'Tidak ada sesi yang cocok dengan filter saat ini.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Coba pilih mapel lain atau ubah status PR.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7D758A)),
          ),
        ],
      ),
    );
  }
}

class _StudentJournalData {
  const _StudentJournalData({
    required this.entries,
    required this.subjects,
    required this.totalSessions,
    required this.completedSessions,
    required this.pendingHomeworkCount,
    required this.submittedHomeworkCount,
    required this.reviewedHomeworkCount,
    required this.materialCount,
    required this.activeTutorCount,
    required this.totalStudyHours,
  });

  final List<_JournalEntry> entries;
  final List<_SubjectSummary> subjects;
  final int totalSessions;
  final int completedSessions;
  final int pendingHomeworkCount;
  final int submittedHomeworkCount;
  final int reviewedHomeworkCount;
  final int materialCount;
  final int activeTutorCount;
  final int totalStudyHours;

  List<String> get availableSubjects => [
    'Semua',
    ...subjects.map((subject) => subject.subject),
  ];

  List<_JournalEntry> filteredEntries({
    required String subject,
    required _JournalHomeworkFilter homeworkFilter,
    required _JournalSortOrder sortOrder,
  }) {
    final filtered = entries.where((entry) {
      final matchSubject =
          subject == 'Semua' || entry.booking.subject == subject;
      final matchHomework = switch (homeworkFilter) {
        _JournalHomeworkFilter.all => true,
        _JournalHomeworkFilter.pending =>
          entry.record?.homeworkStatus == HomeworkStatus.assigned,
        _JournalHomeworkFilter.submitted =>
          entry.record?.homeworkStatus == HomeworkStatus.submitted,
        _JournalHomeworkFilter.reviewed =>
          entry.record?.homeworkStatus == HomeworkStatus.reviewed,
        _JournalHomeworkFilter.noHomework =>
          entry.record == null || !entry.record!.hasHomework,
      };
      return matchSubject && matchHomework;
    }).toList();
    filtered.sort((a, b) {
      final compare = a.session.sessionStart.compareTo(b.session.sessionStart);
      return sortOrder == _JournalSortOrder.newestFirst ? -compare : compare;
    });
    return filtered.toList(growable: false);
  }

  factory _StudentJournalData.fromData({
    required List<BookingItem> bookings,
    required List<BookingSession> sessions,
    required List<SessionLearningRecord> records,
  }) {
    final bookingById = {for (final booking in bookings) booking.id: booking};
    final recordBySessionId = {
      for (final record in records) record.sessionId: record,
    };
    final sortedSessions = [...sessions]
      ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));

    final entries = sortedSessions
        .where((session) => bookingById.containsKey(session.bookingId))
        .map(
          (session) => _JournalEntry(
            booking: bookingById[session.bookingId]!,
            session: session,
            record: recordBySessionId[session.id],
          ),
        )
        .toList(growable: false);

    final completedSessions = sessions
        .where(
          (session) =>
              session.status == BookingSessionStatus.confirmed ||
              session.status == BookingSessionStatus.disputedResolved,
        )
        .length;

    final pendingHomeworkCount = records
        .where((record) => record.homeworkStatus == HomeworkStatus.assigned)
        .length;
    final submittedHomeworkCount = records
        .where((record) => record.homeworkStatus == HomeworkStatus.submitted)
        .length;
    final reviewedHomeworkCount = records
        .where((record) => record.homeworkStatus == HomeworkStatus.reviewed)
        .length;

    final materialCount = records.where((record) => record.hasMaterial).length;
    final activeTutorCount = bookings
        .map((booking) => booking.tutorUid)
        .toSet()
        .length;
    final totalStudyHours = bookings.isEmpty
        ? 0
        : (sessions.fold<int>(
                    0,
                    (sum, session) =>
                        sum +
                        (bookingById[session.bookingId]?.durationMinutes ?? 0),
                  ) /
                  60)
              .round();

    final subjectStats = <String, _SubjectSummaryBuilder>{};
    for (final entry in entries) {
      final builder = subjectStats.putIfAbsent(
        entry.booking.subject,
        () => _SubjectSummaryBuilder(subject: entry.booking.subject),
      );
      builder.totalSessions += 1;
      if (entry.session.status == BookingSessionStatus.confirmed ||
          entry.session.status == BookingSessionStatus.disputedResolved) {
        builder.completedSessions += 1;
      }
      if (entry.record?.homeworkStatus == HomeworkStatus.assigned) {
        builder.pendingHomeworkCount += 1;
      }
    }

    return _StudentJournalData(
      entries: entries,
      subjects: subjectStats.values
          .map((item) => item.build())
          .toList(growable: false),
      totalSessions: sessions.length,
      completedSessions: completedSessions,
      pendingHomeworkCount: pendingHomeworkCount,
      submittedHomeworkCount: submittedHomeworkCount,
      reviewedHomeworkCount: reviewedHomeworkCount,
      materialCount: materialCount,
      activeTutorCount: activeTutorCount,
      totalStudyHours: totalStudyHours,
    );
  }
}

class _JournalEntry {
  const _JournalEntry({
    required this.booking,
    required this.session,
    required this.record,
  });

  final BookingItem booking;
  final BookingSession session;
  final SessionLearningRecord? record;
}

class _SubjectSummary {
  const _SubjectSummary({
    required this.subject,
    required this.totalSessions,
    required this.completedSessions,
    required this.pendingHomeworkCount,
  });

  final String subject;
  final int totalSessions;
  final int completedSessions;
  final int pendingHomeworkCount;
}

class _SubjectSummaryBuilder {
  _SubjectSummaryBuilder({required this.subject});

  final String subject;
  int totalSessions = 0;
  int completedSessions = 0;
  int pendingHomeworkCount = 0;

  _SubjectSummary build() {
    return _SubjectSummary(
      subject: subject,
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      pendingHomeworkCount: pendingHomeworkCount,
    );
  }
}

String _formatSessionDate(DateTime value) {
  return '${value.day}/${value.month}/${value.year} • '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _homeworkFilterLabel(_JournalHomeworkFilter filter) {
  switch (filter) {
    case _JournalHomeworkFilter.all:
      return 'Semua';
    case _JournalHomeworkFilter.pending:
      return 'PR Pending';
    case _JournalHomeworkFilter.submitted:
      return 'PR Dikumpulkan';
    case _JournalHomeworkFilter.reviewed:
      return 'PR Direview';
    case _JournalHomeworkFilter.noHomework:
      return 'Tanpa PR';
  }
}
