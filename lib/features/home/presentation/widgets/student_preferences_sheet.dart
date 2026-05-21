import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/home/application/recommendation_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentPreferencesSheet extends ConsumerStatefulWidget {
  const StudentPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StudentPreferencesSheet(),
    );
  }

  @override
  ConsumerState<StudentPreferencesSheet> createState() =>
      _StudentPreferencesSheetState();
}

class _StudentPreferencesSheetState
    extends ConsumerState<StudentPreferencesSheet> {
  final List<String> _availableSubjects = const [
    'Matematika',
    'IPA',
    'IPS',
    'Fisika',
    'Kimia',
    'Biologi',
    'Bahasa Inggris',
    'Bahasa Indonesia',
    'IPAS',
    'Sejarah',
  ];

  final List<String> _selectedSubjects = <String>[];
  double _maxPrice = 150000.0;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(currentUserProfileProvider).value;

    if (!_isInitialized && userProfile != null) {
      _selectedSubjects.addAll(userProfile.preferredSubjects);
      if (userProfile.maxPricePreference > 0) {
        _maxPrice = userProfile.maxPricePreference;
      }
      _isInitialized = true;
    }

    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.filter_24_filled,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferensi Belajar',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atur untuk memfokuskan rekomendasi tutor terbaikmu',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Subjects Section
                  Text(
                    'Mata Pelajaran yang Diminati',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSubjects.map((subject) {
                      final isSelected = _selectedSubjects.contains(subject);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(subject),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSubjects.add(subject);
                            } else {
                              _selectedSubjects.remove(subject);
                            }
                          });
                        },
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Budget Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Anggaran Maksimal per Jam',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Rp ${_maxPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _maxPrice,
                    min: 30000.0,
                    max: 300000.0,
                    divisions: 27,
                    label: 'Rp ${_maxPrice.toStringAsFixed(0)}',
                    onChanged: (value) {
                      setState(() {
                        _maxPrice = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp 30.000',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Rp 300.000',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // Save Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_selectedSubjects.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan pilih minimal 1 mata pelajaran.'),
                              ),
                            );
                            return;
                          }
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          setState(() {
                            _isSaving = true;
                          });
                          try {
                            await ref
                                .read(recommendationControllerProvider)
                                .updatePreferences(
                                  preferredSubjects: _selectedSubjects,
                                  maxPricePreference: _maxPrice,
                                );
                            navigator.pop();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Preferensi belajar berhasil diperbarui!'),
                              ),
                            );
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Gagal memperbarui preferensi: $e'),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Preferensi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
