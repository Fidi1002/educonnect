import 'package:educonnect/features/availability/data/repositories/tutor_availability_repository.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TutorDetailPage extends ConsumerWidget {
  const TutorDetailPage({required this.tutorId, super.key});

  static const routeName = 'tutor-detail';
  static const routePath = '/student/tutors/:tutorId';

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorAsync = ref.watch(tutorProfileByIdProvider(tutorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tutor')),
      body: tutorAsync.when(
        data: (profile) {
          if (profile == null || !profile.isActive) {
            return const Center(child: Text('Profil tutor tidak tersedia.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: profile.photoUrl.isNotEmpty
                      ? Image.network(
                          profile.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, _) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image, size: 44),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, size: 60),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                profile.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(profile.rating.toStringAsFixed(1)),
                  const SizedBox(width: 6),
                  Text('(${profile.totalReviews} ulasan)'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      profile.locationLabel.isEmpty
                          ? 'Lokasi belum diisi tutor'
                          : profile.locationLabel,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              Text(
                'Mata Pelajaran',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.subjects
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
              const Divider(height: 28),
              Text(
                'Jam & Pengalaman',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Harga: Rp ${profile.pricePerHour} / jam'),
              const SizedBox(height: 4),
              Text('Pengalaman: ${profile.experienceYears} tahun'),
              const SizedBox(height: 4),
              Text(profile.experienceDescription),
              const Divider(height: 28),
              Text(
                'Deskripsi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(profile.bio),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _showCreateBookingDialog(
                  context: context,
                  ref: ref,
                  tutorUid: tutorId,
                  subjects: profile.subjects,
                ),
                child: const Text('Ajukan Booking'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(height: 12),
                const Text(
                  'Gagal memuat detail tutor. Silakan coba lagi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(tutorProfileByIdProvider(tutorId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateBookingDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String tutorUid,
    required List<String> subjects,
  }) async {
    final messageController = TextEditingController();
    final durationOptions = <int>[60, 90, 120];
    var selectedSubject = subjects.isNotEmpty ? subjects.first : 'Umum';
    var selectedDuration = durationOptions.first;
    DateTime? selectedDate;
    DateTime? selectedDateTime;
    var availableStartTimes = <DateTime>[];
    var loadingTimes = false;

    Future<void> loadAvailableTimes(StateSetter setState) async {
      if (selectedDate == null) {
        return;
      }
      setState(() {
        loadingTimes = true;
        availableStartTimes = <DateTime>[];
        selectedDateTime = null;
      });
      try {
        final times = await ref
            .read(tutorAvailabilityRepositoryProvider)
            .fetchAvailableStartTimes(
              tutorUid: tutorUid,
              date: selectedDate!,
              durationMinutes: selectedDuration,
            );
        setState(() {
          availableStartTimes = times;
        });
      } finally {
        setState(() {
          loadingTimes = false;
        });
      }
    }

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Buat Booking Kelas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(labelText: 'Mapel'),
                      items: <String>{...subjects, 'Umum'}
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          selectedSubject = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedDuration,
                      decoration: const InputDecoration(labelText: 'Durasi'),
                      items: durationOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text('$item menit'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          selectedDuration = value;
                        });
                        if (selectedDate != null) {
                          loadAvailableTimes(setState);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                          initialDate: DateTime.now(),
                        );
                        if (date == null || !context.mounted) {
                          return;
                        }
                        setState(() {
                          selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          selectedDateTime = null;
                          availableStartTimes = <DateTime>[];
                        });
                        await loadAvailableTimes(setState);
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        selectedDate == null
                            ? 'Pilih tanggal belajar'
                            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      ),
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(height: 10),
                      if (loadingTimes)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (availableStartTimes.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                          ),
                          child: const Text(
                            'Tidak ada slot tersedia untuk tanggal ini. Pilih tanggal lain atau minta tutor update jadwal.',
                          ),
                        )
                      else ...[
                        Text(
                          'Pilih jam tersedia',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableStartTimes.map((time) {
                            final isSelected =
                                selectedDateTime?.isAtSameMomentAs(time) ??
                                false;
                            final label =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  selectedDateTime = time;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan untuk tutor (opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: selectedDateTime == null
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submit != true || selectedDateTime == null || !context.mounted) {
      messageController.dispose();
      return;
    }

    try {
      await ref
          .read(bookingControllerProvider)
          .createBooking(
            tutorUid: tutorUid,
            subject: selectedSubject,
            sessionStart: selectedDateTime!,
            durationMinutes: selectedDuration,
            message: messageController.text,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil diajukan.')),
      );
    } on Exception catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error is PostgrestException
          ? error.message
          : 'Gagal membuat booking. Coba lagi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      messageController.dispose();
    }
  }
}
