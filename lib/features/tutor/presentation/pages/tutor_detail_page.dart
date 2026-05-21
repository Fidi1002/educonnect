import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/availability/application/tutor_availability_controller.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:educonnect/features/tutor/application/tutor_review_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TutorDetailPage extends ConsumerWidget {
  const TutorDetailPage({required this.tutorId, super.key});

  static const routeName = 'tutor-detail';
  static const routePath = '/student/tutors/:tutorId';

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorAsync = ref.watch(tutorProfileByIdProvider(tutorId));
    final availabilityAsync = ref.watch(
      tutorAvailabilityByTutorProvider(tutorId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: tutorAsync.when(
        data: (profile) {
          if (profile == null || !profile.isActive) {
            return Scaffold(
              appBar: AppBar(title: const Text('Detail Tutor')),
              body: const AppEmptyState(
                message: 'Profil tutor tidak tersedia.',
                hint:
                    'Tutor ini mungkin belum aktif atau belum melengkapi profilnya.',
                icon: FluentIcons.person_search_24_regular,
                fullScreen: true,
              ),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: const Color(0xFF4B176E),
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (profile.photoUrl.isNotEmpty)
                            Image.network(profile.photoUrl, fit: BoxFit.cover)
                          else
                            Container(
                              color: const Color(0xFFD6C8E3),
                              child: const Icon(
                                FluentIcons.person_24_regular,
                                size: 80,
                                color: Color(0xFF4B176E),
                              ),
                            ),
                          // Gradient overlay for better text visibility and blending
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black45,
                                  Colors.transparent,
                                  Color(0x99000000),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Info
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.displayName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF191622),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            FluentIcons.location_24_regular,
                                            size: 16,
                                            color: Color(0xFF718096),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              profile.locationLabel.isEmpty
                                                  ? 'Lokasi belum diisi'
                                                  : profile.locationLabel,
                                              style: const TextStyle(
                                                color: Color(0xFF718096),
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        FluentIcons.star_24_filled,
                                        color: Color(0xFFFFB020),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF191622),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Stats Row
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: FluentIcons.money_24_regular,
                                    title: 'Tarif',
                                    value: 'Rp ${profile.pricePerHour}/jam',
                                    color: const Color(0xFF0F766E),
                                    bgColor: const Color(0xFFE4F7EF),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: FluentIcons.certificate_24_regular,
                                    title: 'Konsistensi',
                                    value:
                                        '${profile.consistencyScore.toStringAsFixed(0)}%',
                                    color: const Color(0xFF5B21B6),
                                    bgColor: const Color(0xFFEADCF8),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Info Banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4B176E),
                                    Color(0xFFFF1377),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Siap Booking Paket Belajar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Pilih paket 1-6 bulan dengan slot tutor pilihanmu.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                            const Text(
                              'Mata Pelajaran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191622),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.subjects
                                  .map((item) => _ModernTag(label: item))
                                  .toList(),
                            ),

                            const SizedBox(height: 32),
                            const Text(
                              'Tentang Tutor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191622),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.bio.isEmpty
                                  ? 'Tutor belum menulis deskripsi diri.'
                                  : profile.bio,
                              style: const TextStyle(
                                color: Color(0xFF4A5568),
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ketersediaan Waktu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF191622),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showAvailabilityModal(
                                    context,
                                    availabilityAsync,
                                  ),
                                  icon: const Icon(
                                    FluentIcons.calendar_ltr_24_regular,
                                    color: Color(0xFF4B176E),
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFF3F0F7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _AvailabilityPreview(
                              availabilityAsync: availabilityAsync,
                            ),

                            const SizedBox(height: 32),
                            const Text(
                              'Ulasan Siswa',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191622),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ReviewsList(tutorId: tutorId),

                            // Bottom padding for the floating bar
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Bottom Bar
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Harga mulai',
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Rp ${profile.pricePerHour}/jam',
                            style: const TextStyle(
                              color: Color(0xFF1A202C),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _startBooking(context, profile),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4B176E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Booking Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: AppLoadingState(message: 'Memuat profil tutor...'),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: AppErrorState(
            message: 'Gagal memuat detail tutor.',
            detail: error.toString(),
            onRetry: () => ref.invalidate(tutorProfileByIdProvider(tutorId)),
            fullScreen: true,
          ),
        ),
      ),
    );
  }

  void _startBooking(BuildContext context, TutorProfile tutor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BookingPackageSheet(tutor: tutor);
      },
    );
  }

  void _showAvailabilityModal(
    BuildContext context,
    AsyncValue<List<TutorAvailabilitySlot>> availabilityAsync,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Ketersediaan Waktu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tutor siap mengajar di jadwal berikut:',
                style: TextStyle(color: Color(0xFF718096)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: availabilityAsync.when(
                  data: (slots) {
                    if (slots.isEmpty) {
                      return const Center(
                        child: Text(
                          'Tutor belum mengatur jadwal ketersediaan.',
                          style: TextStyle(color: Color(0xFF718096)),
                        ),
                      );
                    }

                    final grouped = _groupAvailability(slots);
                    final sortedKeys = grouped.keys.toList()
                      ..sort(
                        (a, b) =>
                            _weekdaySortKey(a).compareTo(_weekdaySortKey(b)),
                      );

                    return ListView.separated(
                      itemCount: sortedKeys.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final day = sortedKeys[index];
                        final daySlots = grouped[day]!;
                        return _AvailabilityDayCard(
                          weekdayLabel: day,
                          slots: daySlots,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      const Center(child: Text('Gagal memuat ketersediaan.')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF718096), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTag extends StatelessWidget {
  const _ModernTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4B176E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AvailabilityPreview extends StatelessWidget {
  const _AvailabilityPreview({required this.availabilityAsync});
  final AsyncValue<List<TutorAvailabilitySlot>> availabilityAsync;

  @override
  Widget build(BuildContext context) {
    return availabilityAsync.when(
      data: (slots) {
        if (slots.isEmpty) {
          return const Text(
            'Jadwal belum tersedia',
            style: TextStyle(
              color: Color(0xFF718096),
              fontStyle: FontStyle.italic,
            ),
          );
        }

        final grouped = _groupAvailability(slots);
        final topDays = grouped.keys.take(3).toList();

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topDays.map((day) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    FluentIcons.clock_16_regular,
                    size: 14,
                    color: Color(0xFF718096),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    day,
                    style: const TextStyle(
                      color: Color(0xFF4A5568),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const Text('Gagal memuat jadwal'),
    );
  }
}

class _AvailabilityDayCard extends StatelessWidget {
  const _AvailabilityDayCard({required this.weekdayLabel, required this.slots});

  final String weekdayLabel;
  final List<TutorAvailabilitySlot> slots;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekdayLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF191622),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots
                .map(
                  (slot) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${slot.startLabel} - ${slot.endLabel}',
                      style: const TextStyle(
                        color: Color(0xFF4B176E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

Map<String, List<TutorAvailabilitySlot>> _groupAvailability(
  List<TutorAvailabilitySlot> slots,
) {
  final grouped = <String, List<TutorAvailabilitySlot>>{};
  for (final slot in slots) {
    grouped.putIfAbsent(slot.weekdayLabel, () => []).add(slot);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  return grouped;
}

int _weekdaySortKey(String label) {
  const mapping = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };
  return mapping[label] ?? 99;
}

// ----------------------------------------------------------------------
// Reviews
// ----------------------------------------------------------------------

class _ReviewsList extends ConsumerWidget {
  const _ReviewsList({required this.tutorId});
  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(tutorReviewsProvider(tutorId));
    
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada ulasan untuk tutor ini.',
                style: TextStyle(color: Color(0xFF718096)),
              ),
            ),
          );
        }

        // Calculate statistics
        final totalCount = reviews.length;
        final ratingCounts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        var totalSum = 0.0;
        for (final r in reviews) {
          totalSum += r.rating;
          final roundedRating = r.rating.round().clamp(1, 5);
          ratingCounts[roundedRating] = (ratingCounts[roundedRating] ?? 0) + 1;
        }
        final averageRating = totalCount > 0 ? totalSum / totalCount : 0.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Rating Breakdown Card
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left side: Big Average Rating
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF191622),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          final isFilled = index < averageRating.floor();
                          return Icon(
                            isFilled ? FluentIcons.star_16_filled : FluentIcons.star_16_regular,
                            size: 14,
                            color: const Color(0xFFFFB224),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'dari $totalCount ulasan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Vertical divider
                  Container(
                    width: 1,
                    height: 80,
                    color: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(width: 24),
                  // Right side: Bar distribution
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final star = 5 - index;
                        final count = ratingCounts[star] ?? 0;
                        final percentage = totalCount > 0 ? count / totalCount : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                '$star',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF718096),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                FluentIcons.star_12_filled,
                                size: 10,
                                color: Color(0xFFFFB224),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    color: const Color(0xFF4B176E),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 20,
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            
            // List of Reviews
            ...reviews.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(
                studentName: r.studentName ?? 'Siswa Tanpa Nama',
                rating: r.rating,
                comment: r.reviewText,
                date: DateFormat('dd MMM yyyy').format(r.createdAt.toLocal()),
                photoUrl: r.studentPhotoUrl,
              ),
            )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Gagal memuat ulasan')),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.date,
    this.photoUrl,
  });

  final String studentName;
  final double rating;
  final String comment;
  final String date;
  final String? photoUrl;

  String _maskName(String name) {
    if (name.isEmpty) return 'Siswa Tersembunyi';
    final parts = name.trim().split(' ');
    final maskedParts = parts.map((part) {
      if (part.length <= 2) {
        return '${part[0]}*';
      }
      return part.substring(0, 2) + '*' * (part.length - 2);
    });
    return maskedParts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final maskedStudentName = _maskName(studentName);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF3F0F7),
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Text(
                        maskedStudentName.isNotEmpty ? maskedStudentName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xFF4B176E),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maskedStudentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191622),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FluentIcons.star_16_filled,
                      size: 12,
                      color: Color(0xFFA16207),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFA16207),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(color: Color(0xFF4A5568), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Booking Sheet
// ----------------------------------------------------------------------

class _BookingPackageSheet extends StatefulWidget {
  const _BookingPackageSheet({required this.tutor});
  final TutorProfile tutor;

  @override
  State<_BookingPackageSheet> createState() => _BookingPackageSheetState();
}

class _BookingPackageSheetState extends State<_BookingPackageSheet> {
  int _selectedMonths = 1;
  int _selectedSessionsPerWeek = 1;

  int get _totalSessions => _selectedMonths * 4 * _selectedSessionsPerWeek;
  num get _totalPrice => _totalSessions * widget.tutor.pricePerHour;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Pilih Paket Belajar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF191622),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Durasi Paket (Bulan)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [1, 2, 3, 6].map((months) {
                final isSelected = _selectedMonths == months;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedMonths = months),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4B176E)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4B176E)
                                : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '$months Bln',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4A5568),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text(
              'Sesi per Minggu',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [1, 2].map((sessions) {
                final isSelected = _selectedSessionsPerWeek == sessions;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedSessionsPerWeek = sessions),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4B176E)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4B176E)
                                : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '$sessions Sesi',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4A5568),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Sesi',
                        style: TextStyle(color: Color(0xFF718096)),
                      ),
                      Text(
                        '$_totalSessions sesi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga',
                        style: TextStyle(
                          color: Color(0xFF1A202C),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rp $_totalPrice',
                        style: const TextStyle(
                          color: Color(0xFF4B176E),
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, _) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _goToScheduleSelection,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4B176E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Lanjutkan ke Jadwal',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToScheduleSelection() {
    Navigator.of(context).pop(); // close package sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BookingScheduleSelectionSheet(
          tutor: widget.tutor,
          packageMonths: _selectedMonths,
          sessionsPerWeek: _selectedSessionsPerWeek,
        );
      },
    );
  }
}

class _BookingScheduleSelectionSheet extends ConsumerStatefulWidget {
  const _BookingScheduleSelectionSheet({
    required this.tutor,
    required this.packageMonths,
    required this.sessionsPerWeek,
  });

  final TutorProfile tutor;
  final int packageMonths;
  final int sessionsPerWeek;

  @override
  ConsumerState<_BookingScheduleSelectionSheet> createState() =>
      _BookingScheduleSelectionSheetState();
}

class _BookingScheduleSelectionSheetState
    extends ConsumerState<_BookingScheduleSelectionSheet> {
  final _selectedSlots = <TutorAvailabilitySlot>[];

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(tutorAvailabilityByTutorProvider(widget.tutor.uid));
    final bookedSlotsAsync =
        ref.watch(tutorBookedWeeklySlotsProvider(widget.tutor.uid));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(
            'Pilih ${widget.sessionsPerWeek} Jadwal Mingguan',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF191622),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jadwal ini akan terkunci untuk seluruh periode paket belajarmu.',
            style: TextStyle(color: Color(0xFF718096)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: availabilityAsync.when(
              data: (slots) {
                if (slots.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tutor belum mengatur ketersediaan waktu mengajar.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final bookedSlots = bookedSlotsAsync.valueOrNull ?? const [];
                final grouped = _groupAvailability(slots);
                final sortedKeys = grouped.keys.toList()
                  ..sort(
                    (a, b) => _weekdaySortKey(a).compareTo(_weekdaySortKey(b)),
                  );

                return ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final day = sortedKeys[index];
                    final daySlots = grouped[day]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4B176E),
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: daySlots.map((slot) {
                            final isSelected = _selectedSlots.contains(slot);
                            
                            // Check if this specific slot is already booked by another student
                            final isBooked = bookedSlots.any((b) =>
                                b.weekday == slot.weekday &&
                                b.startTime == slot.startTime &&
                                b.endTime == slot.endTime);

                            return InkWell(
                              onTap: isBooked
                                  ? null
                                  : () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedSlots.remove(slot);
                                        } else {
                                          if (_selectedSlots.length <
                                              widget.sessionsPerWeek) {
                                            _selectedSlots.add(slot);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Kamu hanya bisa memilih ${widget.sessionsPerWeek} jadwal.',
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      });
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isBooked
                                      ? const Color(0xFFF1F5F9)
                                      : isSelected
                                          ? const Color(0xFF4B176E)
                                          : Colors.white,
                                  border: Border.all(
                                    color: isBooked
                                        ? const Color(0xFFE2E8F0)
                                        : isSelected
                                            ? const Color(0xFF4B176E)
                                            : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isBooked
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            FluentIcons.lock_closed_24_regular,
                                            size: 14,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${slot.startLabel} - ${slot.endLabel}',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              decoration: TextDecoration.lineThrough,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '${slot.startLabel} - ${slot.endLabel}',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF4A5568),
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                        ),
                                      ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat jadwal')),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _selectedSlots.length == widget.sessionsPerWeek
                      ? () => _submitBooking(ref)
                      : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4B176E),
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Konfirmasi & Booking',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitBooking(WidgetRef ref) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Kamu harus login terlebih dahulu.');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final ctrl = ref.read(bookingControllerProvider);

      final realSlots =
          _selectedSlots
              .map(
                (s) => BookingWeeklySlot(
                  weekday: s.weekday,
                  startTime: s.startTime,
                  endTime: s.endTime,
                ),
              )
              .toList();

      await ctrl.createBooking(
        tutorUid: widget.tutor.uid,
        subject: widget.tutor.subjects.firstOrNull ?? 'Mapel Umum',
        packageStartDate: DateTime.now().add(const Duration(days: 1)),
        packageMonths: widget.packageMonths,
        weeklySlots: realSlots,
        durationMinutes: 60,
        message: 'Saya siap untuk belajar',
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // dialog
      Navigator.of(context).pop(); // sheet

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil diajukan!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

