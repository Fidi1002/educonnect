import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/home/application/nearby_tutor_controller.dart';
import 'package:educonnect/features/home/application/tutor_controller.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:educonnect/features/home/presentation/models/tutor_discovery_filter.dart';
import 'package:educonnect/features/home/presentation/widgets/tutor_filter_sheet.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_detail_page.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum TutorSortOption { ratingDesc, distanceAsc, priceAsc, priceDesc }

class TutorListPage extends ConsumerStatefulWidget {
  const TutorListPage({super.key});

  static const routeName = 'tutor-list';
  static const routePath = '/student/tutors';

  @override
  ConsumerState<TutorListPage> createState() => _TutorListPageState();
}

class _TutorListPageState extends ConsumerState<TutorListPage> {
  final TextEditingController _searchController = TextEditingController();
  TutorSortOption _sortOption = TutorSortOption.ratingDesc;
  TutorDiscoveryFilter _filter = TutorDiscoveryFilter.empty;
  int _visibleCount = 25;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(userLocationProvider);
    final radiusKm = ref.watch(searchRadiusKmProvider);
    final nearbyTutorsAsync = ref.watch(nearbyTutorsProvider);
    final fallbackTutorsAsync = ref.watch(activeTutorsProvider);
    final tutorsAsync = location == null ? fallbackTutorsAsync : nearbyTutorsAsync;
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Tutor')),
      body: tutorsAsync.when(
        data: (tutors) {
          final categories = _buildCategories(tutors);
          final filtered = applyTutorDiscoveryFilters(
            tutors: tutors,
            query: _searchController.text,
            filter: _filter,
          );
          _sortTutors(filtered, _sortOption);
          final visible = filtered.take(_visibleCount).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {
                    _visibleCount = 25;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari tutor atau mapel...',
                  prefixIcon: const Icon(FluentIcons.search_24_regular),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SortSelector(
                      selected: _sortOption,
                      onSelected: (value) {
                        setState(() {
                          _sortOption = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final result = await showTutorFilterSheet(
                        context: context,
                        initialFilter: _filter,
                        categories: categories,
                        minAvailablePrice: _minPrice(tutors),
                        maxAvailablePrice: _maxPrice(tutors),
                        currentRadiusKm: radiusKm,
                      );
                      if (result != null) {
                        setState(() {
                          _filter = result;
                          _visibleCount = 25;
                        });
                      }
                    },
                    icon: const Icon(FluentIcons.options_24_regular),
                    label: const Text('Filter'),
                  ),
                ],
              ),
              if (_filter.hasActiveFilters) ...[
                const SizedBox(height: 12),
                TutorActiveFilterChips(
                  filter: _filter,
                  onClearAll: () {
                    setState(() {
                      _filter = TutorDiscoveryFilter.empty;
                      _visibleCount = 25;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const _EmptyState()
              else ...[
                Text(
                  'Menampilkan ${visible.length} dari ${filtered.length} tutor',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ...visible.map((tutor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TutorTile(
                      tutor: tutor,
                      onTap: () => context.pushNamed(
                        TutorDetailPage.routeName,
                        pathParameters: {'tutorId': tutor.uid},
                      ),
                    ).animate().fade(delay: (visible.indexOf(tutor) * 50).ms, duration: 400.ms).slideX(begin: 0.1, curve: Curves.easeOut),
                  );
                }),
                if (visible.length < filtered.length)
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _visibleCount += 25;
                      });
                    },
                    child: const Text('Muat lebih banyak'),
                  ),
              ],
            ],
          );
        },
        loading: () => const AppLoadingState(message: 'Memuat daftar tutor...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat daftar tutor.',
          detail: error.toString(),
          onRetry: () {
            ref.invalidate(nearbyTutorsProvider);
            ref.invalidate(activeTutorsProvider);
          },
          fullScreen: true,
        ),
      ),
    );
  }

  void _sortTutors(List<TutorSummary> tutors, TutorSortOption option) {
    switch (option) {
      case TutorSortOption.ratingDesc:
        tutors.sort((a, b) => b.rating.compareTo(a.rating));
      case TutorSortOption.distanceAsc:
        tutors.sort((a, b) {
          final ad = a.distanceFromUserKm ?? 9999;
          final bd = b.distanceFromUserKm ?? 9999;
          return ad.compareTo(bd);
        });
      case TutorSortOption.priceAsc:
        tutors.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      case TutorSortOption.priceDesc:
        tutors.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
    }
  }

  List<String> _buildCategories(List<TutorSummary> items) {
    final set = <String>{'All'};
    for (final tutor in items) {
      set.addAll(tutor.subjects);
    }
    return set.toList();
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
}

class _SortSelector extends StatelessWidget {
  const _SortSelector({required this.selected, required this.onSelected});

  final TutorSortOption selected;
  final ValueChanged<TutorSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TutorSortOption>(
      segments: const [
        ButtonSegment(
          value: TutorSortOption.ratingDesc,
          label: Text('Rating'),
          icon: Icon(FluentIcons.star_24_filled),
        ),
        ButtonSegment(
          value: TutorSortOption.distanceAsc,
          label: Text('Terdekat'),
          icon: Icon(FluentIcons.location_24_regular),
        ),
        ButtonSegment(
          value: TutorSortOption.priceAsc,
          label: Text('Murah'),
          icon: Icon(FluentIcons.arrow_down_24_regular),
        ),
        ButtonSegment(
          value: TutorSortOption.priceDesc,
          label: Text('Mahal'),
          icon: Icon(FluentIcons.arrow_up_24_regular),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

class _TutorTile extends StatelessWidget {
  const _TutorTile({required this.tutor, required this.onTap});

  final TutorSummary tutor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          tutor.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(FluentIcons.star_24_filled, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(tutor.rating.toStringAsFixed(1)),
                const SizedBox(width: 8),
                Text('(${tutor.totalReviews})'),
                const SizedBox(width: 12),
                const Icon(FluentIcons.book_24_regular, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tutor.subjects.isEmpty
                        ? 'Mapel belum diisi'
                        : tutor.subjects.join(', '),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Mulai dari Rp ${tutor.pricePerHour}/jam'),
            if (tutor.distanceFromUserKm != null) ...[
              const SizedBox(height: 4),
              Text('Jarak ${tutor.distanceFromUserKm!.toStringAsFixed(1)} km'),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFE8DBF4),
              ),
              child: Text(
                'Consistency ${tutor.consistencyScore.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF4B176E),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        trailing: CircleAvatar(
          backgroundColor: Colors.teal.shade200,
          backgroundImage: tutor.photoUrl.isNotEmpty
              ? NetworkImage(tutor.photoUrl)
              : null,
          child: tutor.photoUrl.isEmpty ? const Icon(FluentIcons.person_24_regular) : null,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: const Text('Tutor tidak ditemukan untuk pencarian ini.'),
    );
  }
}
