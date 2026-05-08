import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/features/home/presentation/models/tutor_discovery_filter.dart';
import 'package:flutter/material.dart';

Future<TutorDiscoveryFilter?> showTutorFilterSheet({
  required BuildContext context,
  required TutorDiscoveryFilter initialFilter,
  required List<String> categories,
  required num minAvailablePrice,
  required num maxAvailablePrice,
  required double currentRadiusKm,
}) {
  return showModalBottomSheet<TutorDiscoveryFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _TutorFilterSheet(
        initialFilter: initialFilter,
        categories: categories,
        minAvailablePrice: minAvailablePrice,
        maxAvailablePrice: maxAvailablePrice,
        currentRadiusKm: currentRadiusKm,
      );
    },
  );
}

class TutorActiveFilterChips extends StatelessWidget {
  const TutorActiveFilterChips({
    required this.filter,
    required this.onClearAll,
    super.key,
  });

  final TutorDiscoveryFilter filter;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (!filter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];
    if (filter.subject != 'All') {
      chips.add(_PillLabel(label: filter.subject));
    }
    if (filter.minRating > 0) {
      chips.add(_PillLabel(label: 'Rating ${filter.minRating.toStringAsFixed(1)}+'));
    }
    if (filter.minPrice != null || filter.maxPrice != null) {
      chips.add(
        _PillLabel(
          label:
              'Rp ${filter.minPrice?.round() ?? 0} - ${filter.maxPrice?.round() ?? 0}',
        ),
      );
    }
    if (filter.maxDistanceKm != null) {
      chips.add(_PillLabel(label: '≤ ${filter.maxDistanceKm!.toStringAsFixed(0)} km'));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...chips,
        ActionChip(
          onPressed: onClearAll,
          label: const Text('Reset'),
          avatar: const Icon(FluentIcons.dismiss_24_regular, size: 16),
        ),
      ],
    );
  }
}

class _TutorFilterSheet extends StatefulWidget {
  const _TutorFilterSheet({
    required this.initialFilter,
    required this.categories,
    required this.minAvailablePrice,
    required this.maxAvailablePrice,
    required this.currentRadiusKm,
  });

  final TutorDiscoveryFilter initialFilter;
  final List<String> categories;
  final num minAvailablePrice;
  final num maxAvailablePrice;
  final double currentRadiusKm;

  @override
  State<_TutorFilterSheet> createState() => _TutorFilterSheetState();
}

class _TutorFilterSheetState extends State<_TutorFilterSheet> {
  late String _selectedSubject;
  late RangeValues _priceRange;
  late double _minRating;
  late bool _useDistanceCap;
  late double _distanceCap;

  @override
  void initState() {
    super.initState();
    final minPrice = widget.minAvailablePrice.toDouble();
    final maxPrice = widget.maxAvailablePrice.toDouble();
    _selectedSubject = widget.initialFilter.subject;
    _priceRange = RangeValues(
      (widget.initialFilter.minPrice ?? minPrice).toDouble().clamp(minPrice, maxPrice),
      (widget.initialFilter.maxPrice ?? maxPrice).toDouble().clamp(minPrice, maxPrice),
    );
    _minRating = widget.initialFilter.minRating;
    _useDistanceCap = widget.initialFilter.maxDistanceKm != null;
    _distanceCap = widget.initialFilter.maxDistanceKm ?? widget.currentRadiusKm;
  }

  @override
  Widget build(BuildContext context) {
    final minPrice = widget.minAvailablePrice.toDouble();
    final maxPrice = widget.maxAvailablePrice.toDouble();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Tutor',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              'Mapel',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedSubject == category,
                  onSelected: (_) => setState(() => _selectedSubject = category),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Harga per jam',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            RangeSlider(
              values: _priceRange,
              min: minPrice,
              max: maxPrice <= minPrice ? minPrice + 1 : maxPrice,
              divisions: 6,
              labels: RangeLabels(
                'Rp ${_priceRange.start.round()}',
                'Rp ${_priceRange.end.round()}',
              ),
              onChanged: (values) => setState(() => _priceRange = values),
            ),
            Text(
              'Rp ${_priceRange.start.round()} - Rp ${_priceRange.end.round()}',
            ),
            const SizedBox(height: 16),
            Text(
              'Rating minimum',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Semua')),
                ButtonSegment(value: 4, label: Text('4.0+')),
                ButtonSegment(value: 4.5, label: Text('4.5+')),
              ],
              selected: {_minRating},
              onSelectionChanged: (selection) {
                setState(() => _minRating = selection.first);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Batasi jarak'),
              subtitle: Text(
                _useDistanceCap
                    ? 'Maksimal ${_distanceCap.toStringAsFixed(0)} km'
                    : 'Ikuti radius pencarian aktif',
              ),
              value: _useDistanceCap,
              onChanged: (value) => setState(() => _useDistanceCap = value),
            ),
            if (_useDistanceCap)
              Slider(
                value: _distanceCap.clamp(1, 20),
                min: 1,
                max: 20,
                divisions: 19,
                label: '${_distanceCap.toStringAsFixed(0)} km',
                onChanged: (value) => setState(() => _distanceCap = value),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, TutorDiscoveryFilter.empty),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        TutorDiscoveryFilter(
                          subject: _selectedSubject,
                          minPrice: _priceRange.start.round() <= minPrice.round()
                              ? null
                              : _priceRange.start.round(),
                          maxPrice: _priceRange.end.round() >= maxPrice.round()
                              ? null
                              : _priceRange.end.round(),
                          minRating: _minRating,
                          maxDistanceKm: _useDistanceCap ? _distanceCap : null,
                        ),
                      );
                    },
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E8FB),
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
