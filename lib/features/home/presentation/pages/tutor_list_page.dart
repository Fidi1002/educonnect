import 'package:educonnect/features/home/application/tutor_controller.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum TutorSortOption { ratingDesc, priceAsc, priceDesc }

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
  int _visibleCount = 25;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutorsAsync = ref.watch(activeTutorsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Tutor')),
      body: tutorsAsync.when(
        data: (tutors) {
          final filtered = tutors
              .where((item) => item.matchesKeyword(_searchController.text))
              .toList();
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
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SortSelector(
                selected: _sortOption,
                onSelected: (value) {
                  setState(() {
                    _sortOption = value;
                  });
                },
              ),
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
                    ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Gagal memuat tutor: $error')),
      ),
    );
  }

  void _sortTutors(List<TutorSummary> tutors, TutorSortOption option) {
    switch (option) {
      case TutorSortOption.ratingDesc:
        tutors.sort((a, b) => b.rating.compareTo(a.rating));
      case TutorSortOption.priceAsc:
        tutors.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      case TutorSortOption.priceDesc:
        tutors.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
    }
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
          icon: Icon(Icons.star_outline),
        ),
        ButtonSegment(
          value: TutorSortOption.priceAsc,
          label: Text('Harga Termurah'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: TutorSortOption.priceDesc,
          label: Text('Harga Tertinggi'),
          icon: Icon(Icons.arrow_upward),
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
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(tutor.rating.toStringAsFixed(1)),
                const SizedBox(width: 8),
                Text('(${tutor.totalReviews})'),
                const SizedBox(width: 12),
                const Icon(Icons.menu_book, size: 16),
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
          child: tutor.photoUrl.isEmpty ? const Icon(Icons.person) : null,
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
