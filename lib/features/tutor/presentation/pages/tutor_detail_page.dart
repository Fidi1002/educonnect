import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/availability/application/tutor_availability_controller.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:educonnect/features/tutor/application/tutor_review_controller.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_booking_sheet.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TutorDetailPage extends ConsumerWidget {
  const TutorDetailPage({required this.tutorId, super.key});

  static const routeName = 'tutor-detail';
  static const routePath = '/student/tutors/:tutorId';

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (tutorId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tutor')),
        body: const AppEmptyState(
          message: 'Profil tutor tidak tersedia.',
          hint: 'ID Tutor tidak valid atau profil tidak dapat ditemukan.',
          icon: FluentIcons.person_search_24_regular,
          fullScreen: true,
        ),
      );
    }

    final tutorAsync = ref.watch(tutorProfileByIdProvider(tutorId));
    final availabilityAsync = ref.watch(
      tutorAvailabilityByTutorProvider(tutorId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Info
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            profile.displayName,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          if (profile.verificationStatus == 'approved') ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              FluentIcons.checkmark_circle_20_filled,
                                              color: Color(0xFF0284C7),
                                              size: 20,
                                            ),
                                          ],
                                        ],
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
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1B2336) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                                    boxShadow: isDark ? null : const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FluentIcons.star_24_filled,
                                        color: Color(0xFFFFB020),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profile.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.onSurface,
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
                            Text(
                              'Mata Pelajaran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
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

                            if (profile.teachingLevels.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Tingkat Sekolah Sasaran',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: profile.teachingLevels
                                    .map((item) => _ModernTag(
                                          label: item,
                                          color: const Color(0xFF0F766E),
                                          bgColor: const Color(0xFFE4F7EF),
                                        ))
                                    .toList(),
                              ),
                            ],

                            if (profile.languages.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Bahasa Pengantar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: profile.languages
                                    .map((item) => _ModernTag(
                                          label: item,
                                          color: const Color(0xFF4B176E),
                                          bgColor: const Color(0xFFF3F0F7),
                                        ))
                                    .toList(),
                              ),
                            ],

                            if (profile.introductionVideoUrl != null &&
                                profile.introductionVideoUrl!.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              Text(
                                'Video Perkenalan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InAppYoutubePlayer(videoUrl: profile.introductionVideoUrl!),
                            ],

                            const SizedBox(height: 32),
                            Text(
                              'Tentang Tutor',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.bio.isEmpty
                                  ? 'Tutor belum menulis deskripsi diri.'
                                  : profile.bio,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),

                            if (profile.experienceCv != null && profile.experienceCv!.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              Text(
                                'Portofolio & CV Mengajar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildCvTimeline(profile.experienceCv, isDark),
                            ],

                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ketersediaan Waktu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showAvailabilityModal(
                                    context,
                                    availabilityAsync,
                                  ),
                                  icon: Icon(
                                    FluentIcons.calendar_ltr_24_regular,
                                    color: isDark ? Colors.white : const Color(0xFF4B176E),
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF28354E) : const Color(0xFFF3F0F7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _AvailabilityPreview(
                              availabilityAsync: availabilityAsync,
                            ),

                            const SizedBox(height: 32),
                            Text(
                              'Ulasan Siswa',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1B2336).withValues(alpha: 0.75)
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark 
                              ? const Color(0xFF28354E).withValues(alpha: 0.5) 
                              : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                        ),
                        boxShadow: isDark ? null : const [
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
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
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
                ),
              ),
            ],
          );
        },
        loading: () => const _TutorDetailSkeleton(),
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
        return TutorBookingPackageSheet(tutor: tutor);
      },
    );
  }

  void _showAvailabilityModal(
    BuildContext context,
    AsyncValue<List<TutorAvailabilitySlot>> availabilityAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2336) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
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

  Widget _buildCvTimeline(List<Map<String, dynamic>>? cvList, bool isDark) {
    if (cvList == null || cvList.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(cvList.length, (index) {
        final item = cvList[index];
        final isLast = index == cvList.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4B176E),
                      border: Border.all(color: isDark ? const Color(0xFF1B2336) : Colors.white, width: 2.5),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
               Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['role'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF191622),
                        ),
                      ),
                      Text(
                        "${item['institution'] ?? '-'} (${item['period'] ?? '-'})",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B176E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
        boxShadow: isDark ? null : const [
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
  const _ModernTag({
    required this.label,
    this.color,
    this.bgColor,
  });

  final String label;
  final Color? color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBgColor = isDark ? const Color(0xFF28354E) : const Color(0xFFF7F9FF);
    final fallbackTextColor = isDark ? Colors.white : const Color(0xFF4B176E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor ?? fallbackBgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? fallbackTextColor,
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topDays.map((day) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2336) : Colors.white,
                border: Border.all(
                  color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0),
                ),
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
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF4A5568),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF28354E) : const Color(0xFFE9E2F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekdayLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
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
                      color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${slot.startLabel} - ${slot.endLabel}',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF4B176E),
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
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Rating Breakdown Card
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2336) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                boxShadow: isDark ? null : const [
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
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
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
                    color: isDark ? const Color(0xFF28354E) : const Color(0xFFF1F5F9),
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
                                    backgroundColor: isDark ? const Color(0xFF28354E) : const Color(0xFFF1F5F9),
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
              child: TutorReviewCard(
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
      loading: () => const _ReviewsSkeleton(),
      error: (e, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Gagal memuat ulasan'),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Premium Skeleton Shimmer Components
// ----------------------------------------------------------------------

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const _SkeletonBox({
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? const Color(0xFF1B2336) 
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark 
        ? const Color(0xFF28354E) 
        : const Color(0xFFF1F5F9);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: 1500.ms,
      color: highlightColor,
    );
  }
}

class _TutorDetailSkeleton extends StatelessWidget {
  const _TutorDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SkeletonBox(
                  width: double.infinity,
                  height: 300,
                  borderRadius: 0,
                ),
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SkeletonBox(width: 180, height: 28, borderRadius: 8),
                                  SizedBox(height: 8),
                                  _SkeletonBox(width: 120, height: 16, borderRadius: 6),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            _SkeletonBox(
                              width: 60,
                              height: 60,
                              borderRadius: 16,
                              margin: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 96,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1B2336) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                                  boxShadow: isDark ? null : const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SkeletonBox(width: 32, height: 32, borderRadius: 12),
                                    Spacer(),
                                    _SkeletonBox(width: 80, height: 16, borderRadius: 6),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 96,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1B2336) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                                  boxShadow: isDark ? null : const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SkeletonBox(width: 32, height: 32, borderRadius: 12),
                                    Spacer(),
                                    _SkeletonBox(width: 80, height: 16, borderRadius: 6),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2336) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                          ),
                          child: const Row(
                            children: [
                              _SkeletonBox(width: 40, height: 40, borderRadius: 12),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SkeletonBox(width: 140, height: 16, borderRadius: 6),
                                    SizedBox(height: 6),
                                    _SkeletonBox(width: 200, height: 12, borderRadius: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _SkeletonBox(width: 140, height: 20, borderRadius: 8),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            _SkeletonBox(width: 70, height: 32, borderRadius: 16),
                            SizedBox(width: 8),
                            _SkeletonBox(width: 85, height: 32, borderRadius: 16),
                            SizedBox(width: 8),
                            _SkeletonBox(width: 60, height: 32, borderRadius: 16),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const _SkeletonBox(width: 120, height: 20, borderRadius: 8),
                        const SizedBox(height: 12),
                        const _SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                        const SizedBox(height: 8),
                        const _SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                        const SizedBox(height: 8),
                        const _SkeletonBox(width: 240, height: 14, borderRadius: 4),
                        const SizedBox(height: 32),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SkeletonBox(width: 160, height: 20, borderRadius: 8),
                            _SkeletonBox(width: 40, height: 40, borderRadius: 20),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            _SkeletonBox(width: 80, height: 30, borderRadius: 12),
                            SizedBox(width: 8),
                            _SkeletonBox(width: 90, height: 30, borderRadius: 12),
                            SizedBox(width: 8),
                            _SkeletonBox(width: 75, height: 30, borderRadius: 12),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const _SkeletonBox(width: 120, height: 20, borderRadius: 8),
                        const SizedBox(height: 16),
                        const _ReviewsSkeleton(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                color: isDark 
                    ? const Color(0xFF1B2336).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(32),
                border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                boxShadow: isDark ? null : const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SkeletonBox(width: 60, height: 12, borderRadius: 4),
                      SizedBox(height: 6),
                      _SkeletonBox(width: 100, height: 18, borderRadius: 6),
                    ],
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: _SkeletonBox(height: 48, borderRadius: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2336) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
            boxShadow: isDark ? null : const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Column(
                children: [
                  _SkeletonBox(width: 50, height: 48, borderRadius: 8),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 70, height: 12, borderRadius: 4),
                ],
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 80,
                color: isDark ? const Color(0xFF28354E) : const Color(0xFFF1F5F9),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: List.generate(5, (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        _SkeletonBox(width: 12, height: 12, borderRadius: 2),
                        SizedBox(width: 8),
                        Expanded(child: _SkeletonBox(height: 6, borderRadius: 3)),
                        SizedBox(width: 8),
                        _SkeletonBox(width: 16, height: 12, borderRadius: 2),
                      ],
                    ),
                  )),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(2, (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2336) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 120, height: 16, borderRadius: 6),
                    SizedBox(height: 6),
                    _SkeletonBox(width: 80, height: 12, borderRadius: 4),
                    SizedBox(height: 12),
                    _SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    _SkeletonBox(width: 180, height: 14, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _InAppYoutubePlayer extends StatefulWidget {
  const _InAppYoutubePlayer({required this.videoUrl});

  final String videoUrl;

  @override
  State<_InAppYoutubePlayer> createState() => _InAppYoutubePlayerState();
}

class _InAppYoutubePlayerState extends State<_InAppYoutubePlayer> {
  YoutubePlayerController? _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (_videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );
    }
  }

  @override
  void deactivate() {
    _controller?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null || _controller == null) {
      return InkWell(
        onTap: () => _launchVideoUrl(context, widget.videoUrl),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1377).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.15,
                child: Icon(
                  FluentIcons.video_clip_24_regular,
                  size: 120,
                  color: Colors.white,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFFFF1377),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Buka Video Perkenalan Tutor (Eksternal)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B176E).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFFF1377),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFFF1377),
          handleColor: Color(0xFFFF1377),
        ),
      ),
    );
  }

  Future<void> _launchVideoUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka video perkenalan.')),
      );
    }
  }
}
