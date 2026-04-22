import 'package:educonnect/features/availability/data/repositories/tutor_availability_repository.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
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
    final availabilityAsync = ref.watch(
      tutorAvailabilityByTutorProvider(tutorId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tutor')),
      body: tutorAsync.when(
        data: (profile) {
          if (profile == null || !profile.isActive) {
            return const Center(child: Text('Profil tutor tidak tersedia.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
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
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 44,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.person, size: 60),
                              ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${profile.rating.toStringAsFixed(1)} / 5',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: List<Widget>.generate(
                                5,
                                (index) => Icon(
                                  Icons.star,
                                  size: 16,
                                  color: profile.rating >= index + 1
                                      ? Colors.amber
                                      : Colors.amber.shade200,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFFE8DBF4),
                              ),
                              child: Text(
                                'Consistency ${profile.consistencyScore.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Color(0xFF4B176E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    profile.locationLabel.isEmpty
                                        ? 'Lokasi belum diisi tutor'
                                        : profile.locationLabel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _SectionTitle(
                              context: context,
                              title: 'Mata Pelajaran',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.subjects
                                  .map(
                                    (item) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.black26,
                                        ),
                                      ),
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const Divider(height: 20),
                            _SectionTitle(
                              context: context,
                              title: 'Jam Tersedia',
                            ),
                            const SizedBox(height: 8),
                            availabilityAsync.when(
                              data: (slots) {
                                if (slots.isEmpty) {
                                  return const Text('Tutor belum set jadwal.');
                                }
                                return Column(
                                  children: slots
                                      .map(
                                        (slot) => _AvailabilityRow(slot: slot),
                                      )
                                      .toList(),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(),
                              ),
                              error: (_, _) =>
                                  const Text('Jadwal tidak tersedia saat ini.'),
                            ),
                            const Divider(height: 20),
                            _SectionTitle(context: context, title: 'Deskripsi'),
                            const SizedBox(height: 8),
                            Text(
                              profile.bio.isEmpty
                                  ? profile.experienceDescription
                                  : profile.bio,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _showCreateBookingDialog(
                      context: context,
                      ref: ref,
                      tutorUid: tutorId,
                      subjects: profile.subjects,
                    ),
                    child: const Text('Submit'),
                  ),
                ),
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
    final packageOptions = <int>[1, 2, 3, 6];
    var selectedSubject = subjects.isNotEmpty ? subjects.first : 'Umum';
    var selectedDuration = durationOptions.first;
    var selectedPackageMonths = 1;
    DateTime? packageStartDate;
    var selectedSlots = <BookingWeeklySlot>[];
    var availableWeeklySlots = <BookingWeeklySlot>[];
    var loadingSlots = true;

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (loadingSlots && availableWeeklySlots.isEmpty) {
              Future<void>.microtask(() async {
                final rawSlots = await ref
                    .read(tutorAvailabilityRepositoryProvider)
                    .fetchTutorAvailability(tutorUid);
                if (!context.mounted) {
                  return;
                }
                setState(() {
                  availableWeeklySlots = rawSlots
                      .map(
                        (slot) => BookingWeeklySlot(
                          weekday: slot.weekday,
                          startTime: slot.startTime,
                          endTime: slot.endTime,
                        ),
                      )
                      .toList(growable: false);
                  loadingSlots = false;
                });
              });
            }

            return AlertDialog(
              title: const Text('Buat Booking Paket'),
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
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedPackageMonths,
                      decoration: const InputDecoration(labelText: 'Paket'),
                      items: packageOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text('$item bulan'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          selectedPackageMonths = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 120),
                          ),
                          initialDate: DateTime.now(),
                        );
                        if (date == null || !context.mounted) {
                          return;
                        }
                        setState(() {
                          packageStartDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                        });
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        packageStartDate == null
                            ? 'Pilih tanggal mulai paket'
                            : '${packageStartDate!.day}/${packageStartDate!.month}/${packageStartDate!.year}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilih 2 jadwal per minggu',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    if (loadingSlots)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (availableWeeklySlots.isEmpty)
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
                          'Tutor belum mengisi jadwal ketersediaan. Minta tutor update jadwal dulu.',
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableWeeklySlots.map((slot) {
                          final key =
                              '${slot.weekday}-${slot.startTime}-${slot.endTime}';
                          final isSelected = selectedSlots.any(
                            (item) =>
                                '${item.weekday}-${item.startTime}-${item.endTime}' ==
                                key,
                          );
                          return FilterChip(
                            label: Text(
                              '${slot.weekdayLabel} ${slot.timeLabel}',
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (selectedSlots.length >= 2) {
                                    return;
                                  }
                                  selectedSlots = [...selectedSlots, slot];
                                } else {
                                  selectedSlots = selectedSlots
                                      .where(
                                        (item) =>
                                            '${item.weekday}-${item.startTime}-${item.endTime}' !=
                                            key,
                                      )
                                      .toList();
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
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
                  onPressed:
                      selectedSlots.length != 2 || packageStartDate == null
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

    if (submit != true ||
        packageStartDate == null ||
        selectedSlots.length != 2 ||
        !context.mounted) {
      messageController.dispose();
      return;
    }

    try {
      await ref
          .read(bookingControllerProvider)
          .createBooking(
            tutorUid: tutorUid,
            subject: selectedSubject,
            packageStartDate: packageStartDate!,
            packageMonths: selectedPackageMonths,
            weeklySlots: selectedSlots,
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

final tutorAvailabilityByTutorProvider = FutureProvider.autoDispose
    .family<List<TutorAvailabilitySlot>, String>((ref, tutorUid) {
      return ref
          .watch(tutorAvailabilityRepositoryProvider)
          .fetchTutorAvailability(tutorUid);
    });

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.context, required this.title});

  final BuildContext context;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        this.context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.slot});

  final TutorAvailabilitySlot slot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(slot.weekdayLabel)),
          Text('${slot.startLabel} - ${slot.endLabel}'),
        ],
      ),
    );
  }
}
