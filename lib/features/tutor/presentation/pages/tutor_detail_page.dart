import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/availability/data/repositories/tutor_availability_repository.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
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
            return const AppEmptyState(
              message: 'Profil tutor tidak tersedia.',
              hint: 'Tutor ini mungkin belum aktif atau belum melengkapi profilnya.',
              icon: Icons.person_search_outlined,
              fullScreen: true,
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
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
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE8E2F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _QualityBadge(
                                  icon: Icons.star_rounded,
                                  label:
                                      '${profile.rating.toStringAsFixed(1)} (${profile.totalReviews} ulasan)',
                                  background: const Color(0xFFFFF1C7),
                                  foreground: const Color(0xFFA16207),
                                ),
                                _QualityBadge(
                                  icon: Icons.verified_outlined,
                                  label:
                                      'Consistency ${profile.consistencyScore.toStringAsFixed(0)}%',
                                  background: const Color(0xFFEADCF8),
                                  foreground: const Color(0xFF5B21B6),
                                ),
                                _QualityBadge(
                                  icon: Icons.payments_outlined,
                                  label: 'Rp ${profile.pricePerHour}/jam',
                                  background: const Color(0xFFE4F7EF),
                                  foreground: const Color(0xFF0F766E),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _QuickInfoGrid(profile: profile),
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
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: const Color(0xFFF7F0FE),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.book_online_outlined,
                                        color: Color(0xFF4B176E),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Siap Booking Paket Belajar',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF28163D),
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pilih paket 1, 2, 3, atau 6 bulan dengan maksimal 2 sesi per minggu dari slot yang tutor sediakan.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF6F6780),
                                        ),
                                  ),
                                ],
                              ),
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
                              title: 'Availability Tutor',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gunakan slot di bawah untuk memilih jadwal paket yang paling cocok.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF7D7788)),
                            ),
                            const SizedBox(height: 10),
                            availabilityAsync.when(
                              data: (slots) {
                                if (slots.isEmpty) {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh,
                                    ),
                                    child: const Text(
                                      'Tutor belum set jadwal. Minta tutor melengkapi availability terlebih dahulu.',
                                    ),
                                  );
                                }
                                final grouped = _groupAvailability(slots);
                                return Column(
                                  children: grouped.entries
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _AvailabilityDayCard(
                                            weekdayLabel: entry.key,
                                            slots: entry.value,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(),
                              ),
                              error: (error, _) => AppErrorState(
                                message: 'Jadwal tutor tidak tersedia saat ini.',
                                detail: error.toString(),
                                fullScreen: false,
                              ),
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
                            if (profile.experienceDescription.trim().isNotEmpty &&
                                profile.bio.trim() !=
                                    profile.experienceDescription.trim()) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Pengalaman Mengajar',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile.experienceDescription,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mulai dari Rp ${profile.pricePerHour}/jam',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Booking paket belajar dengan 2 slot mingguan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF7C7488),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showCreateBookingDialog(
                            context: context,
                            ref: ref,
                            tutorUid: tutorId,
                            subjects: profile.subjects,
                          ),
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: const Text('Booking Paket Belajar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(message: 'Memuat detail tutor...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat detail tutor.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(tutorProfileByIdProvider(tutorId)),
          fullScreen: true,
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F0FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Aturan paket: pilih durasi 1/2/3/6 bulan dan tepat 2 slot mingguan dari availability tutor.',
                      ),
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
                      'Pilih tepat 2 jadwal per minggu',
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

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoGrid extends StatelessWidget {
  const _QuickInfoGrid({required this.profile});

  final TutorProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickInfoCard(
            icon: Icons.workspace_premium_outlined,
            label: 'Ulasan',
            value: '${profile.totalReviews}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickInfoCard(
            icon: Icons.history_edu_outlined,
            label: 'Pengalaman',
            value: '${profile.experienceYears} tahun',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickInfoCard(
            icon: Icons.menu_book_outlined,
            label: 'Mapel',
            value: '${profile.subjects.length}',
          ),
        ),
      ],
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  const _QuickInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE5F1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4B176E)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF241A33),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A7585)),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityDayCard extends StatelessWidget {
  const _AvailabilityDayCard({
    required this.weekdayLabel,
    required this.slots,
  });

  final String weekdayLabel;
  final List<TutorAvailabilitySlot> slots;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekdayLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots
                .map(
                  (slot) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E8FB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${slot.startLabel} - ${slot.endLabel}',
                      style: const TextStyle(
                        color: Color(0xFF4B176E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

Map<String, List<TutorAvailabilitySlot>> _groupAvailability(
  List<TutorAvailabilitySlot> slots,
) {
  final grouped = <String, List<TutorAvailabilitySlot>>{};
  for (final slot in slots) {
    grouped.putIfAbsent(slot.weekdayLabel, () => <TutorAvailabilitySlot>[]).add(
      slot,
    );
  }
  return grouped;
}
