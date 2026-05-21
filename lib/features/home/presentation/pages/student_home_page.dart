import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/home/application/nearby_tutor_controller.dart';
import 'package:educonnect/features/home/application/tutor_controller.dart';
import 'package:educonnect/features/home/application/recommendation_controller.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/home/presentation/models/tutor_discovery_filter.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_list_page.dart';
import 'package:educonnect/features/home/presentation/widgets/tutor_filter_sheet.dart';
import 'package:educonnect/features/home/presentation/widgets/student_preferences_sheet.dart';
import 'package:educonnect/features/notifications/application/notification_controller.dart';
import 'package:educonnect/features/notifications/presentation/pages/notifications_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentHomePage extends ConsumerStatefulWidget {
  const StudentHomePage({super.key});

  static const routeName = 'student-home';
  static const routePath = '/student/home';

  @override
  ConsumerState<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends ConsumerState<StudentHomePage> {
  final TextEditingController _searchController = TextEditingController();
  TutorDiscoveryFilter _filter = TutorDiscoveryFilter.empty;
  bool _hasTriggeredPreferences = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(nearbyTutorControllerProvider).refreshUserLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-trigger preferensi belajar murid jika terdeteksi kosong
    ref.listen<AsyncValue<AppUserProfile?>>(currentUserProfileProvider, (previous, next) {
      final profile = next.valueOrNull;
      if (profile != null && profile.preferredSubjects.isEmpty && !_hasTriggeredPreferences) {
        _hasTriggeredPreferences = true;
        StudentPreferencesSheet.show(context);
      }
    });

    final profileAsync = ref.watch(currentUserProfileProvider);
    final nearbyTutorsAsync = ref.watch(nearbyTutorsProvider);
    final fallbackTutorsAsync = ref.watch(activeTutorsProvider);
    final location = ref.watch(userLocationProvider);
    final locationError = ref.watch(locationErrorProvider);
    final radiusKm = ref.watch(searchRadiusKmProvider);
    final unreadChatCount =
        ref.watch(unreadMessagesCountProvider).valueOrNull ?? 0;
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    return profileAsync.when(
      data: (profile) {
        final sourceTutors = location == null
            ? fallbackTutorsAsync
            : nearbyTutorsAsync;
        return sourceTutors.when(
          data: (tutors) => _HomeBody(
            profile: profile,
            tutors: tutors,
            filter: _filter,
            searchController: _searchController,
            radiusKm: radiusKm,
            locationText: location == null
                ? 'Lokasi belum terdeteksi'
                : 'Lokasi aktif (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})',
            locationError: locationError,
            unreadChatCount: unreadChatCount,
            unreadNotifications: unreadNotifications,
            onSearchChanged: (_) => setState(() {}),
            onFilterChanged: (filter) {
              setState(() => _filter = filter);
            },
            onRadiusChipTap: (radius) {
              ref.read(nearbyTutorControllerProvider).setSearchRadius(radius);
            },
            onRefreshLocation: () {
              ref.read(nearbyTutorControllerProvider).refreshUserLocation();
            },
          ),
          loading: () => const AppLoadingState(message: 'Memuat tutor...'),
          error: (error, _) => AppErrorState(
            message: 'Gagal memuat daftar tutor.',
            detail: error.toString(),
            onRetry: () {
              ref.invalidate(nearbyTutorsProvider);
              ref.invalidate(activeTutorsProvider);
            },
            fullScreen: true,
          ),
        );
      },
      loading: () => const AppLoadingState(message: 'Memuat akun...'),
      error: (error, _) => AppErrorState(
        message: 'Gagal memuat akun murid.',
        detail: error.toString(),
        onRetry: () => ref.invalidate(currentUserProfileProvider),
        fullScreen: true,
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.profile,
    required this.tutors,
    required this.filter,
    required this.searchController,
    required this.radiusKm,
    required this.locationText,
    required this.locationError,
    required this.unreadChatCount,
    required this.unreadNotifications,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onRadiusChipTap,
    required this.onRefreshLocation,
  });

  final AppUserProfile? profile;
  final List<TutorSummary> tutors;
  final TutorDiscoveryFilter filter;
  final TextEditingController searchController;
  final double radiusKm;
  final String locationText;
  final String? locationError;
  final int unreadChatCount;
  final int unreadNotifications;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TutorDiscoveryFilter> onFilterChanged;
  final ValueChanged<double> onRadiusChipTap;
  final VoidCallback onRefreshLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primary = Color(0xFF4B176E);
    final greetingName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Sahabat Belajar';
    final recommendedTutorsAsync = ref.watch(recommendedTutorsProvider);
    final filteredTutors = applyTutorDiscoveryFilters(
      tutors: tutors,
      query: searchController.text,
      filter: filter,
    );
    final categories = _buildCategories(tutors);
    const radiusOptions = <double>[1, 5, 10, 20];
    final bookings =
        ref.watch(myStudentBookingsProvider).valueOrNull ?? const [];
    final sessions =
        ref.watch(myStudentSessionsProvider).valueOrNull ?? const [];
    final learningRecords =
        ref.watch(myStudentLearningRecordsProvider).valueOrNull ?? const [];
    final dashboard = _StudentDashboardSnapshot.fromData(
      bookings: bookings,
      sessions: sessions,
      learningRecords: learningRecords,
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                onPressed: () => context.pushNamed(NotificationsPage.routeName),
                icon: const Icon(FluentIcons.alert_24_regular, color: primary),
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 2,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                onPressed: () => context.pushNamed(InboxPage.routeName),
                icon: const Icon(FluentIcons.chat_24_regular, color: primary),
              ),
              if (unreadChatCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
        children: [
          _StudentHeroCard(
            greetingName: greetingName,
            dashboard: dashboard,
            onOpenSchedule: () =>
                context.pushNamed(StudentBookingsPage.routeName),
            onOpenTutorSearch: () => context.pushNamed(TutorListPage.routeName),
          ),
          const SizedBox(height: 24),
          const _StudentMetricCards(),
          const SizedBox(height: 32),

          // Section: Rekomendasi Pintar (Fase 3)
          recommendedTutorsAsync.when(
            data: (recTutors) {
              if (recTutors.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rekomendasi Tutor Terbaik',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4B176E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => StudentPreferencesSheet.show(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF1377),
                        ),
                        child: const Text('Ubah Preferensi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recTutors.length,
                      itemBuilder: (context, index) {
                        final tutor = recTutors[index];
                        final score = tutor.recommendationScore ?? 0.0;
                        return _RecommendedTutorCard(tutor: tutor, matchScore: score);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Section: PR & Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PR & Progress Belajar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4B176E),
                  letterSpacing: -0.5,
                ),
              ),
              if (dashboard.pendingHomework.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      context.pushNamed(StudentBookingsPage.routeName),
                  child: const Text('Lihat Semua'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (dashboard.pendingHomework.isNotEmpty)
            _HomeworkProgressList(dashboard: dashboard)
          else
            _EmptyHomeworkCard(),

          const SizedBox(height: 32),

          // Section: Discovery
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temukan Tutor Terbaik',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4B176E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cari berdasarkan mapel, lokasi, atau nama tutor',
                  style: TextStyle(
                    color: const Color(0xFF718096),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4B176E,
                              ).withValues(alpha: 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Cari tutor...',
                            prefixIcon: const Icon(
                              FluentIcons.search_24_regular,
                              color: Color(0xFF4B176E),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: const Color(0xFFFF1377),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () async {
                          final filterResult = await showTutorFilterSheet(
                            context: context,
                            initialFilter: filter,
                            categories: categories,
                            minAvailablePrice: _minPrice(tutors),
                            maxAvailablePrice: _maxPrice(tutors),
                            currentRadiusKm: radiusKm,
                          );
                          if (filterResult != null) {
                            onFilterChanged(filterResult);
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: const Icon(
                            FluentIcons.filter_24_regular,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LocationBadge(
                  locationText: locationText,
                  onRefresh: onRefreshLocation,
                ),
                const SizedBox(height: 16),
                Text(
                  'Radius Pencarian',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4B176E).withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: radiusOptions.map((option) {
                      final selected = radiusKm.round() == option.round();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${option.toInt()} km'),
                          selected: selected,
                          onSelected: (_) => onRadiusChipTap(option),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF4B176E),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF4B176E),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: selected
                                  ? const Color(0xFF4B176E)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          if (filter.hasActiveFilters) ...[
            const SizedBox(height: 16),
            TutorActiveFilterChips(
              filter: filter,
              onClearAll: () => onFilterChanged(TutorDiscoveryFilter.empty),
            ),
          ],

          if (dashboard.activeTutors.isNotEmpty) ...[
            const SizedBox(height: 32),
            _ActiveTutorSection(dashboard: dashboard),
          ],

          const SizedBox(height: 32),

          // Section: Tutor Categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Mapel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4B176E),
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () => context.pushNamed(TutorListPage.routeName),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: categories.map((item) {
              final selected = item == filter.subject;
              return ChoiceChip(
                label: Text(item),
                selected: selected,
                onSelected: (_) =>
                    onFilterChanged(filter.copyWith(subject: item)),
                backgroundColor: const Color(0xFFF7F9FF),
                selectedColor: const Color(0xFF4B176E),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF4B176E)
                      : const Color(0xFFC9D8F2),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF4E475C),
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (filteredTutors.isEmpty)
            const _EmptyTutorState()
          else
            ...filteredTutors.take(15).map((tutor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TutorDiscoveryCard(
                  tutor: tutor,
                  onTap: () => context.pushNamed(
                    TutorDetailPage.routeName,
                    pathParameters: {'tutorId': tutor.uid},
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  List<String> _buildCategories(List<TutorSummary> items) {
    final set = <String>{'All'};
    for (final tutor in items) {
      set.addAll(tutor.subjects);
    }
    return set.toList();
  }
}

class _TutorDiscoveryCard extends StatelessWidget {
  const _TutorDiscoveryCard({required this.tutor, required this.onTap});

  final TutorSummary tutor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasRating = tutor.totalReviews > 0 && tutor.rating > 0;
    final distanceLabel = _distanceLabel(tutor.distanceFromUserKm);
    final consistencyLabel = tutor.consistencyScore <= 0
        ? 'Tutor Baru'
        : '${tutor.consistencyScore.toStringAsFixed(0)}%';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9E3F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF191622),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tutor.subjects.isEmpty
                        ? 'Mapel belum diisi'
                        : tutor.subjects.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7A7388),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _miniTag(
                        icon: FluentIcons.star_24_filled,
                        text: hasRating
                            ? '${tutor.rating.toStringAsFixed(1)} (${tutor.totalReviews})'
                            : 'Belum ada ulasan',
                        foreground: hasRating
                            ? const Color(0xFFA16207)
                            : const Color(0xFF6D667A),
                        background: hasRating
                            ? const Color(0xFFFFF2D2)
                            : const Color(0xFFF2EFF7),
                      ),
                      _miniTag(
                        icon: FluentIcons.location_24_regular,
                        text: distanceLabel,
                        foreground: const Color(0xFF1D4E89),
                        background: const Color(0xFFE8F1FF),
                      ),
                      _miniTag(
                        icon: FluentIcons.certificate_24_regular,
                        text: consistencyLabel,
                        foreground: tutor.consistencyScore <= 0
                            ? const Color(0xFF6D667A)
                            : const Color(0xFF4B176E),
                        background: tutor.consistencyScore <= 0
                            ? const Color(0xFFF2EFF7)
                            : const Color(0xFFEAF2FF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 56,
                child: tutor.photoUrl.isNotEmpty
                    ? Image.network(tutor.photoUrl, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFEFEAF6),
                        child: const Icon(
                          FluentIcons.person_24_regular,
                          size: 26,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTag({
    required IconData icon,
    required String text,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _distanceLabel(double? distanceKm) {
  if (distanceKm == null) {
    return 'Jarak belum tersedia';
  }
  if (distanceKm < 1) {
    return 'Kurang dari 1 km';
  }
  return '${distanceKm.toStringAsFixed(1)} km';
}

num _minPrice(List<TutorSummary> tutors) {
  if (tutors.isEmpty) {
    return 0;
  }
  return tutors
      .map((tutor) => tutor.pricePerHour)
      .reduce((value, element) => value < element ? value : element);
}

num _maxPrice(List<TutorSummary> tutors) {
  if (tutors.isEmpty) {
    return 0;
  }
  return tutors
      .map((tutor) => tutor.pricePerHour)
      .reduce((value, element) => value > element ? value : element);
}

class _EmptyTutorState extends StatelessWidget {
  const _EmptyTutorState();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      message: 'Belum ada tutor yang cocok.',
      hint: 'Coba ubah radius, filter mapel, atau gunakan kata kunci lain.',
      icon: FluentIcons.search_24_regular,
    );
  }
}

// ignore: unused_element
class _StudyBanner extends StatelessWidget {
  const _StudyBanner({required this.onOpenCalendar});

  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -26,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: Icon(
              Icons.laptop_chromebook_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 40,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jadwal Belajar!!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cek jadwal lesmu disini',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onOpenCalendar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4B176E),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Lihat Sekarang'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentDashboardSnapshot {
  const _StudentDashboardSnapshot({
    required this.nextClass,
    required this.activeTutors,
    required this.pendingHomework,
    required this.totalSessions,
    required this.completedSessions,
    required this.activeBookingCount,
    required this.awaitingPaymentCount,
  });

  final _StudentNextClassSummary? nextClass;
  final List<_StudentTutorDigest> activeTutors;
  final List<_StudentHomeworkDigest> pendingHomework;
  final int totalSessions;
  final int completedSessions;
  final int activeBookingCount;
  final int awaitingPaymentCount;

  int get completedPercent {
    if (totalSessions == 0) {
      return 0;
    }
    return ((completedSessions / totalSessions) * 100).round();
  }

  factory _StudentDashboardSnapshot.fromData({
    required List<BookingItem> bookings,
    required List<BookingSession> sessions,
    required List<SessionLearningRecord> learningRecords,
  }) {
    final bookingById = {for (final booking in bookings) booking.id: booking};
    final now = DateTime.now();
    final upcomingSessions =
        sessions
            .where(
              (session) =>
                  session.sessionEnd.isAfter(now) &&
                  session.status != BookingSessionStatus.cancelledByStudent &&
                  session.status != BookingSessionStatus.cancelledByTutor &&
                  session.status != BookingSessionStatus.cancelledEarly &&
                  session.status != BookingSessionStatus.cancelledLate &&
                  session.status != BookingSessionStatus.studentNoShow &&
                  session.status != BookingSessionStatus.tutorNoShow,
            )
            .toList()
          ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
    final nextSession = upcomingSessions.isEmpty
        ? null
        : upcomingSessions.first;
    final nextClass = nextSession == null
        ? null
        : _StudentNextClassSummary(
            booking:
                bookingById[nextSession.bookingId] ??
                BookingItem(
                  id: nextSession.bookingId,
                  studentUid: nextSession.studentUid,
                  tutorUid: nextSession.tutorUid,
                  subject: 'Sesi Belajar',
                  sessionStart: nextSession.sessionStart,
                  durationMinutes: nextSession.sessionEnd
                      .difference(nextSession.sessionStart)
                      .inMinutes,
                  status: BookingStatus.paid,
                  message: '',
                  createdAt: nextSession.sessionStart,
                  totalAmount: 0,
                  paidAt: null,
                  studentName: 'Murid',
                  tutorName: 'Tutor',
                  packageMonths: 1,
                  sessionsPerWeek: 1,
                  packageStartDate: nextSession.sessionStart,
                  packageEndDate: nextSession.sessionEnd,
                  weeklySchedule: const [],
                ),
            session: nextSession,
          );

    final completedSessions = sessions
        .where(
          (session) =>
              session.status == BookingSessionStatus.confirmed ||
              session.status == BookingSessionStatus.disputedResolved,
        )
        .length;

    final activeBookings = bookings
        .where(
          (booking) =>
              (booking.status == BookingStatus.paid ||
                  booking.status == BookingStatus.awaitingPayment) &&
              booking.packageEndDate.isAfter(
                now.subtract(const Duration(days: 1)),
              ),
        )
        .toList();

    final activeTutorMap = <String, _StudentTutorDigest>{};
    for (final booking in activeBookings) {
      activeTutorMap.putIfAbsent(
        booking.tutorUid,
        () => _StudentTutorDigest(
          tutorUid: booking.tutorUid,
          tutorName: booking.tutorName.isEmpty ? 'Tutor' : booking.tutorName,
          subject: booking.subject,
          bookingCount: 1,
        ),
      );
    }

    final pendingHomework =
        learningRecords
            .where((record) => record.homeworkStatus == HomeworkStatus.assigned)
            .map((record) {
              final booking = bookingById[record.bookingId];
              return _StudentHomeworkDigest(
                record: record,
                tutorName: booking?.tutorName ?? 'Tutor',
                subject: booking?.subject ?? 'Materi',
              );
            })
            .toList()
          ..sort(
            (a, b) => (b.record.homeworkAssignedAt ?? b.record.updatedAt)
                .compareTo(a.record.homeworkAssignedAt ?? a.record.updatedAt),
          );

    return _StudentDashboardSnapshot(
      nextClass: nextClass,
      activeTutors: activeTutorMap.values.toList(growable: false),
      pendingHomework: pendingHomework,
      totalSessions: sessions.length,
      completedSessions: completedSessions,
      activeBookingCount: activeBookings.length,
      awaitingPaymentCount: bookings
          .where((booking) => booking.status == BookingStatus.awaitingPayment)
          .length,
    );
  }
}

class _StudentNextClassSummary {
  const _StudentNextClassSummary({
    required this.booking,
    required this.session,
  });

  final BookingItem booking;
  final BookingSession session;

  String get timeLabel {
    final start = session.sessionStart;
    final end = session.sessionEnd;
    return '${_weekdayLabel(start.weekday)}, ${start.day}/${start.month} '
        '${_formatTime(start)} - ${_formatTime(end)}';
  }
}

class _StudentTutorDigest {
  const _StudentTutorDigest({
    required this.tutorUid,
    required this.tutorName,
    required this.subject,
    required this.bookingCount,
  });

  final String tutorUid;
  final String tutorName;
  final String subject;
  final int bookingCount;
}

class _StudentHomeworkDigest {
  const _StudentHomeworkDigest({
    required this.record,
    required this.tutorName,
    required this.subject,
  });

  final SessionLearningRecord record;
  final String tutorName;
  final String subject;
}

class _HeroMiniMetric extends StatelessWidget {
  const _HeroMiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
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
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ActiveTutorSection extends StatelessWidget {
  const _ActiveTutorSection({required this.dashboard});

  final _StudentDashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tutor Aktif',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dashboard.activeTutors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tutor = dashboard.activeTutors[index];
              return Container(
                width: 210,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFC9D8F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B176E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        FluentIcons.person_24_regular,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tutor.tutorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1630),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tutor.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6D6380)),
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

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Sen';
    case DateTime.tuesday:
      return 'Sel';
    case DateTime.wednesday:
      return 'Rab';
    case DateTime.thursday:
      return 'Kam';
    case DateTime.friday:
      return 'Jum';
    case DateTime.saturday:
      return 'Sab';
    case DateTime.sunday:
    default:
      return 'Min';
  }
}

class _StudentHeroCard extends StatelessWidget {
  const _StudentHeroCard({
    required this.greetingName,
    required this.dashboard,
    required this.onOpenSchedule,
    required this.onOpenTutorSearch,
  });

  final String greetingName;
  final _StudentDashboardSnapshot dashboard;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenTutorSearch;

  @override
  Widget build(BuildContext context) {
    final nextClass = dashboard.nextClass;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x224B176E),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -36,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            'EduConnect',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Halo,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          greetingName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nextClass == null
                              ? 'Temukan tutor, pantau jadwal, dan kelola progres belajarmu dari satu tempat.'
                              : 'Kelas berikutnya sudah siap. Cek jadwal, chat tutor, atau lihat progres dari sini.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 14,
                          left: 30,
                          child: _HeroOrbitIcon(
                            icon: FluentIcons.calendar_ltr_24_regular,
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 14,
                          child: _HeroOrbitIcon(
                            icon: FluentIcons.chat_24_regular,
                          ),
                        ),
                        const Icon(
                          FluentIcons.person_24_regular,
                          size: 30,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (nextClass != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            FluentIcons.calendar_ltr_24_regular,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kelas berikutnya',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${nextClass.booking.subject} • ${nextClass.booking.tutorName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextClass.timeLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniMetric(
                      label: 'PR pending',
                      value: '${dashboard.pendingHomework.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMiniMetric(
                      label: 'Tutor aktif',
                      value: '${dashboard.activeTutors.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMiniMetric(
                      label: 'Progress',
                      value: '${dashboard.completedPercent}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onOpenSchedule,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4B176E),
                        minimumSize: const Size.fromHeight(46),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Lihat Jadwal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpenTutorSearch,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        minimumSize: const Size.fromHeight(46),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Cari Tutor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroOrbitIcon extends StatelessWidget {
  const _HeroOrbitIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}

class _StudentMetricCards extends StatelessWidget {
  const _StudentMetricCards();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _MetricCard(
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'Jadwal\nBelajar',
            subtitle: 'Lihat sesi berikutnya',
          ),
          const SizedBox(width: 12),
          _MetricCard(
            icon: Icons.search_rounded,
            iconColor: const Color(0xFF4B176E),
            title: 'Cari\nTutor',
            subtitle: 'Tutor terdekat',
          ),
          const SizedBox(width: 12),
          _MetricCard(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFFF1377),
            title: 'Jurnal\nBelajar',
            subtitle: 'PR & materi',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C4B176E),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4B176E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7B738C),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkProgressList extends StatelessWidget {
  const _HomeworkProgressList({required this.dashboard});

  final _StudentDashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    // Generate some stable fake percentages for visual demo
    final percentages = [70, 80, 45, 90, 30];
    final items = dashboard.pendingHomework.take(3).toList(growable: false);

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final pct = percentages[index % percentages.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: pct / 100,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFFEDF2F7),
                          color: index % 2 == 0
                              ? const Color(0xFF4FD1C5)
                              : const Color(0xFF667EEA),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191622),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.record.homeworkTitle.isEmpty
                            ? 'Task'
                            : item.record.homeworkTitle,
                        style: const TextStyle(color: Color(0xFF718096)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            FluentIcons.clock_12_regular,
                            size: 14,
                            color: const Color(0xFF718096),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2 days left',
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            FluentIcons.person_12_regular,
                            size: 14,
                            color: const Color(0xFF718096),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Individual Task',
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.locationText, required this.onRefresh});

  final String locationText;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.location_24_regular,
            size: 18,
            color: Color(0xFF4B176E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              locationText,
              style: const TextStyle(
                color: Color(0xFF4B176E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(FluentIcons.arrow_sync_24_regular, size: 18),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            color: const Color(0xFF4B176E),
          ),
        ],
      ),
    );
  }
}

class _EmptyHomeworkCard extends StatelessWidget {
  const _EmptyHomeworkCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          'Hore! Tidak ada PR untuk dikerjakan saat ini.',
          style: TextStyle(
            color: Color(0xFF718096),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _RecommendedTutorCard extends StatelessWidget {
  const _RecommendedTutorCard({required this.tutor, required this.matchScore});

  final TutorSummary tutor;
  final double matchScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B176E).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.pushNamed(
            TutorDetailPage.routeName,
            pathParameters: {'tutorUid': tutor.uid},
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: tutor.photoUrl.isNotEmpty
                          ? NetworkImage(tutor.photoUrl)
                          : null,
                      child: tutor.photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${matchScore.toStringAsFixed(0)}% Match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tutor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tutor.subjects.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 10, color: Colors.redAccent),
                          const SizedBox(width: 2),
                          Text(
                            tutor.distanceFromUserKm != null
                                ? '${tutor.distanceFromUserKm!.toStringAsFixed(1)} km'
                                : 'Terdekat',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Rp ${tutor.pricePerHour.toStringAsFixed(0)}/j',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: Color(0xFFFF1377),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

