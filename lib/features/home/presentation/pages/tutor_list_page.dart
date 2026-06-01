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
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  
  bool _isMapView = false;
  TutorSummary? _selectedTutorForMap;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isMapView = !_isMapView;
            _selectedTutorForMap = null;
          });
        },
        backgroundColor: const Color(0xFF4B176E),
        foregroundColor: Colors.white,
        icon: Icon(_isMapView ? FluentIcons.list_24_regular : FluentIcons.map_24_regular),
        label: Text(_isMapView ? 'Lihat Daftar' : 'Lihat Peta'),
      ),
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

          if (_isMapView) {
            return _buildMapView(
              tutors: filtered,
              userLocation: location,
              radiusKm: radiusKm,
              categories: categories,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Semua Tutor',
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

  Widget _buildMapView({
    required List<TutorSummary> tutors,
    required UserLocationState? userLocation,
    required double radiusKm,
    required List<String> categories,
  }) {
    LatLng center = const LatLng(-6.2088, 106.8456); // Jakarta default
    if (userLocation != null) {
      center = LatLng(userLocation.latitude, userLocation.longitude);
    } else if (tutors.isNotEmpty) {
      center = LatLng(tutors.first.latitude, tutors.first.longitude);
    }

    final Set<Marker> markers = {};
    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLocation.latitude, userLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        ),
      );
    }

    for (final tutor in tutors) {
      markers.add(
        Marker(
          markerId: MarkerId(tutor.uid),
          position: LatLng(tutor.latitude, tutor.longitude),
          onTap: () {
            setState(() {
              _selectedTutorForMap = tutor;
            });
          },
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 12,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {
                      _visibleCount = 25;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Cari tutor atau mapel...',
                    prefixIcon: Icon(FluentIcons.search_24_regular),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButton<TutorSortOption>(
                              value: _sortOption,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF191622),
                                fontWeight: FontWeight.bold,
                              ),
                              items: const [
                                DropdownMenuItem(value: TutorSortOption.ratingDesc, child: Text('Sort: Rating')),
                                DropdownMenuItem(value: TutorSortOption.distanceAsc, child: Text('Sort: Terdekat')),
                                DropdownMenuItem(value: TutorSortOption.priceAsc, child: Text('Sort: Murah')),
                                DropdownMenuItem(value: TutorSortOption.priceDesc, child: Text('Sort: Mahal')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _sortOption = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B176E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x204B176E),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.options_24_regular, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_selectedTutorForMap != null)
          Positioned(
            bottom: 96,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFF3F0F7),
                        backgroundImage: _selectedTutorForMap!.photoUrl.isNotEmpty
                            ? NetworkImage(_selectedTutorForMap!.photoUrl)
                            : null,
                        child: _selectedTutorForMap!.photoUrl.isEmpty
                            ? const Icon(FluentIcons.person_24_regular, size: 28, color: Color(0xFF4B176E))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedTutorForMap!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191622),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(FluentIcons.star_16_filled, size: 14, color: Color(0xFFFFB224)),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedTutorForMap!.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${_selectedTutorForMap!.totalReviews} Ulasan)',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTutorForMap!.subjects.isEmpty
                                  ? 'Mapel Umum'
                                  : _selectedTutorForMap!.subjects.join(', '),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B176E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rp ${_selectedTutorForMap!.pricePerHour}/jam',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF191622),
                                  ),
                                ),
                                if (_selectedTutorForMap!.distanceFromUserKm != null)
                                  Text(
                                    '${_selectedTutorForMap!.distanceFromUserKm!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  context.pushNamed(
                                    TutorDetailPage.routeName,
                                    pathParameters: {'tutorId': _selectedTutorForMap!.uid},
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B176E),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Lihat Detail Profil',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTutorForMap = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4B176E);
    final selectedColor = isDark ? const Color(0xFFC084FC) : primaryColor;
    final selectedBgColor = isDark ? const Color(0xFF3B0764) : const Color(0xFFF3E8FF);
    final unselectedBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final textColorSelected = isDark ? const Color(0xFFF3E8FF) : primaryColor;
    final textColorUnselected = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    Widget buildChip(TutorSortOption option, String label, IconData icon) {
      final isSelected = selected == option;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? textColorSelected : textColorUnselected,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? textColorSelected : textColorUnselected,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (val) {
            if (val) onSelected(option);
          },
          backgroundColor: unselectedBgColor,
          selectedColor: selectedBgColor,
          checkmarkColor: Colors.transparent,
          showCheckmark: false,
          elevation: 0,
          pressElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected 
                  ? selectedColor.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            buildChip(
              TutorSortOption.ratingDesc,
              'Rating',
              FluentIcons.star_16_filled,
            ),
            buildChip(
              TutorSortOption.distanceAsc,
              'Terdekat',
              FluentIcons.location_16_filled,
            ),
            buildChip(
              TutorSortOption.priceAsc,
              'Murah',
              FluentIcons.arrow_down_16_regular,
            ),
            buildChip(
              TutorSortOption.priceDesc,
              'Mahal',
              FluentIcons.arrow_up_16_regular,
            ),
          ],
        ),
      ),
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
                const Icon(FluentIcons.star_16_filled, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(tutor.rating.toStringAsFixed(1)),
                const SizedBox(width: 8),
                Text('(${tutor.totalReviews})'),
                const SizedBox(width: 12),
                const Icon(FluentIcons.book_16_regular, size: 16),
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
