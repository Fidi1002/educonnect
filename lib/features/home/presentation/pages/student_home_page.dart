import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/home/application/nearby_tutor_controller.dart';
import 'package:educonnect/features/home/application/tutor_controller.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:educonnect/features/home/presentation/pages/student_study_calendar_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_list_page.dart';
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
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(nearbyTutorControllerProvider).refreshUserLocation();
      await ref.read(bookingControllerProvider).processSmartSessionReminders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            selectedCategory: _selectedCategory,
            searchController: _searchController,
            radiusKm: radiusKm,
            locationText: location == null
                ? 'Lokasi belum terdeteksi'
                : 'Lokasi aktif (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})',
            locationError: locationError,
            unreadChatCount: unreadChatCount,
            unreadNotifications: unreadNotifications,
            onSearchChanged: (_) => setState(() {}),
            onCategoryChanged: (category) {
              setState(() => _selectedCategory = category);
            },
            onRadiusChipTap: (radius) {
              ref.read(nearbyTutorControllerProvider).setSearchRadius(radius);
            },
            onRefreshLocation: () {
              ref.read(nearbyTutorControllerProvider).refreshUserLocation();
            },
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) =>
              _ErrorScreen(message: 'Gagal memuat tutor: $error'),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _ErrorScreen(message: 'Gagal memuat akun: $error'),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.profile,
    required this.tutors,
    required this.selectedCategory,
    required this.searchController,
    required this.radiusKm,
    required this.locationText,
    required this.locationError,
    required this.unreadChatCount,
    required this.unreadNotifications,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onRadiusChipTap,
    required this.onRefreshLocation,
  });

  final AppUserProfile? profile;
  final List<TutorSummary> tutors;
  final String selectedCategory;
  final TextEditingController searchController;
  final double radiusKm;
  final String locationText;
  final String? locationError;
  final int unreadChatCount;
  final int unreadNotifications;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<double> onRadiusChipTap;
  final VoidCallback onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4B176E);
    final greetingName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Sahabat Belajar';
    final filteredTutors = _filterTutors(
      tutors: tutors,
      query: searchController.text,
      selectedCategory: selectedCategory,
    );
    final categories = _buildCategories(tutors);
    const radiusOptions = <double>[1, 5, 10, 20];

    return Scaffold(
      appBar: AppBar(
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                onPressed: () => context.pushNamed(NotificationsPage.routeName),
                icon: const Icon(Icons.notifications_none, color: primary),
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
                icon: const Icon(Icons.chat_bubble_outline, color: primary),
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        children: [
          Text(
            'Hello, $greetingName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF16131D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih tutor sesuai mapel, tingkat kelas,\ndan preferensimu yukkk!!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8F8B99)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'search..',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: Color(0xFF8F8B99),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locationText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8F8B99),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefreshLocation,
                icon: const Icon(Icons.my_location),
                tooltip: 'Refresh lokasi',
              ),
            ],
          ),
          if (locationError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                locationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Wrap(
            spacing: 8,
            children: radiusOptions.map((option) {
              final selected = radiusKm.round() == option.round();
              return ChoiceChip(
                label: Text('${option.toInt()} km'),
                selected: selected,
                onSelected: (_) => onRadiusChipTap(option),
                side: BorderSide(
                  color: selected
                      ? Colors.transparent
                      : const Color(0xFFD6D2DE),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF63606D),
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _StudyBanner(
            onOpenCalendar: () =>
                context.pushNamed(StudentStudyCalendarPage.routeName),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Cari Tutor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.pushNamed(TutorListPage.routeName),
                child: Text(
                  'View All',
                  style: const TextStyle(color: Color(0xFF9A7CB6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: categories.map((item) {
              final selected = item == selectedCategory;
              return ChoiceChip(
                label: Text(item),
                selected: selected,
                onSelected: (_) => onCategoryChanged(item),
                selectedColor: const Color(0xFF4B176E),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
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
                child: Card(
                  child: ListTile(
                    onTap: () => context.pushNamed(
                      TutorDetailPage.routeName,
                      pathParameters: {'tutorId': tutor.uid},
                    ),
                    title: Text(
                      tutor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF191622),
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(tutor.rating.toStringAsFixed(1)),
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          tutor.distanceFromUserKm == null
                              ? '- km'
                              : '${tutor.distanceFromUserKm!.toStringAsFixed(1)} km',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFE8DBF4),
                          ),
                          child: Text(
                            '${tutor.consistencyScore.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Color(0xFF4B176E),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 68,
                        height: 44,
                        child: tutor.photoUrl.isNotEmpty
                            ? Image.network(tutor.photoUrl, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.person),
                              ),
                      ),
                    ),
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

  List<TutorSummary> _filterTutors({
    required List<TutorSummary> tutors,
    required String query,
    required String selectedCategory,
  }) {
    return tutors.where((tutor) {
      final matchQuery = tutor.matchesKeyword(query);
      final matchCategory =
          selectedCategory == 'All' ||
          tutor.subjects.contains(selectedCategory);
      return matchQuery && matchCategory;
    }).toList();
  }
}

class _EmptyTutorState extends StatelessWidget {
  const _EmptyTutorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: const Text('Belum ada tutor dalam radius pencarian ini.'),
    );
  }
}

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
          colors: [Color(0xFF6E2F99), Color(0xFF8C4BC0)],
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

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
