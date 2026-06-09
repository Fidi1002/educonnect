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
    backgroundColor: Colors.transparent,
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
    if (filter.minExperienceYears > 0) {
      chips.add(_PillLabel(label: '${filter.minExperienceYears}+ thn exp'));
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
  late int _minExperience;
  late Set<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    final minPrice = widget.minAvailablePrice.toDouble();
    final maxPrice = widget.maxAvailablePrice.toDouble();
    _selectedSubject = widget.initialFilter.subject;
    _priceRange = RangeValues(
      (widget.initialFilter.minPrice ?? minPrice)
          .toDouble()
          .clamp(minPrice, maxPrice),
      (widget.initialFilter.maxPrice ?? maxPrice)
          .toDouble()
          .clamp(minPrice, maxPrice),
    );
    _minRating = widget.initialFilter.minRating;
    _useDistanceCap = widget.initialFilter.maxDistanceKm != null;
    _distanceCap = widget.initialFilter.maxDistanceKm ?? widget.currentRadiusKm;
    _minExperience = widget.initialFilter.minExperienceYears;
    _selectedDays = Set.from(widget.initialFilter.preferredDays);
  }

  @override
  Widget build(BuildContext context) {
    final minPrice = widget.minAvailablePrice.toDouble();
    final maxPrice = widget.maxAvailablePrice.toDouble();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28354E) : const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Pencarian',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF4B176E),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, TutorDiscoveryFilter.empty),
                child: const Text('Reset Semua'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionHeader('Mata Pelajaran'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.categories.map((category) {
                final isSelected = _selectedSubject == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedSubject = category),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Harga per Jam'),
          RangeSlider(
            values: _priceRange,
            min: minPrice,
            max: maxPrice <= minPrice ? minPrice + 1 : maxPrice,
            divisions: 20,
            activeColor: const Color(0xFFFF1377),
            inactiveColor: isDark ? const Color(0xFF28354E) : const Color(0xFFF3F0F7),
            labels: RangeLabels(
              'Rp ${_priceRange.start.round()}',
              'Rp ${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rp ${minPrice.round()}'),
              Text(
                'Rp ${_priceRange.start.round()} - Rp ${_priceRange.end.round()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF1377),
                ),
              ),
              Text('Rp ${maxPrice.round()}'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Rating Min'),
                    const SizedBox(height: 12),
                    SegmentedButton<double>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Semua')),
                        ButtonSegment(value: 4, label: Text('4.0+')),
                        ButtonSegment(value: 4.5, label: Text('4.5+')),
                      ],
                      selected: {_minRating},
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onSelectionChanged: (selection) {
                        setState(() => _minRating = selection.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Pengalaman'),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Semua')),
                        ButtonSegment(value: 3, label: Text('3th+')),
                        ButtonSegment(value: 5, label: Text('5th+')),
                      ],
                      selected: {_minExperience},
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onSelectionChanged: (selection) {
                        setState(() => _minExperience = selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: _sectionHeader('Batasi Jarak Maksimal'),
            subtitle: Text(
              _useDistanceCap
                  ? 'Tampilkan tutor dalam radius ${_distanceCap.toStringAsFixed(0)} km'
                  : 'Gunakan radius default pencarian',
              style: const TextStyle(fontSize: 12),
            ),
            thumbColor: WidgetStateProperty.all(const Color(0xFFFF1377)),
            trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0xFFFF1377).withValues(alpha: 0.5) : null),
            value: _useDistanceCap,
            onChanged: (value) => setState(() => _useDistanceCap = value),
          ),
          if (_useDistanceCap)
            Slider(
              value: _distanceCap.clamp(1, 20),
              min: 1,
              max: 20,
              divisions: 19,
              activeColor: const Color(0xFFFF1377),
              thumbColor: const Color(0xFFFF1377),
              label: '${_distanceCap.toStringAsFixed(0)} km',
              onChanged: (value) => setState(() => _distanceCap = value),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
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
                    minExperienceYears: _minExperience,
                    preferredDays: _selectedDays,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Terapkan Filter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isDark ? const Color(0xFF28354E) : const Color(0xFFD3DFFB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
