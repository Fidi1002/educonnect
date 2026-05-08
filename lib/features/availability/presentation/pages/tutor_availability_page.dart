import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/availability/application/tutor_availability_controller.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TutorAvailabilityPage extends ConsumerWidget {
  const TutorAvailabilityPage({super.key});

  static const routeName = 'tutor-availability';
  static const routePath = '/tutor/availability';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(myTutorAvailabilityProvider);
    final isLoading = ref.watch(tutorAvailabilityLoadingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Ketersediaan Tutor')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading
            ? null
            : () => _showAddSlotDialog(context: context, ref: ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Slot'),
      ),
      body: slotsAsync.when(
        data: (slots) {
          final grouped = _groupByWeekday(slots);
          final weeklyMinutes = slots.fold<int>(
            0,
            (sum, slot) => sum + _durationMinutes(slot),
          );
          final weeklyHours = (weeklyMinutes / 60).toStringAsFixed(
            weeklyMinutes % 60 == 0 ? 0 : 1,
          );
          final activeDays = grouped.length;

          if (slots.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                _AvailabilitySummaryCard(
                  totalSlots: 0,
                  weeklyHoursLabel: '0',
                  activeDays: 0,
                ),
                SizedBox(height: 16),
                _EmptyAvailabilityState(),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _AvailabilitySummaryCard(
                totalSlots: slots.length,
                weeklyHoursLabel: weeklyHours,
                activeDays: activeDays,
              ),
              const SizedBox(height: 16),
              const _AvailabilityHintCard(),
              const SizedBox(height: 16),
              ...grouped.entries.map((entry) {
                final daySlots = entry.value;
                final dayMinutes = daySlots.fold<int>(
                  0,
                  (sum, slot) => sum + _durationMinutes(slot),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AvailabilityDayCard(
                    weekdayLabel: daySlots.first.weekdayLabel,
                    slotCount: daySlots.length,
                    totalHoursLabel: (dayMinutes / 60).toStringAsFixed(
                      dayMinutes % 60 == 0 ? 0 : 1,
                    ),
                    slots: daySlots,
                    isLoading: isLoading,
                    onDelete: (slot) async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus slot?'),
                          content: Text(
                            'Slot ${slot.weekdayLabel} ${slot.startLabel} - ${slot.endLabel} akan dihapus dari jadwal tutor.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !context.mounted) {
                        return;
                      }
                      try {
                        await ref
                            .read(tutorAvailabilityControllerProvider)
                            .removeSlot(slot.id);
                      } on Exception catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal menghapus slot: ${error.toString()}',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const AppLoadingState(
          message: 'Memuat availability tutor...',
          fullScreen: false,
        ),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat jadwal ketersediaan.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myTutorAvailabilityProvider),
        ),
      ),
    );
  }

  Map<int, List<TutorAvailabilitySlot>> _groupByWeekday(
    List<TutorAvailabilitySlot> slots,
  ) {
    final grouped = <int, List<TutorAvailabilitySlot>>{};
    for (final slot in slots) {
      grouped.putIfAbsent(slot.weekday, () => <TutorAvailabilitySlot>[]).add(
        slot,
      );
    }
    return grouped;
  }

  int _durationMinutes(TutorAvailabilitySlot slot) {
    final start = _toMinutes(slot.startTime);
    final end = _toMinutes(slot.endTime);
    return end - start;
  }

  int _toMinutes(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return (hour * 60) + minute;
  }

  Future<void> _showAddSlotDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    var weekday = 1;
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 9, minute: 0);

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isInvalid =
                (end.hour * 60 + end.minute) <=
                (start.hour * 60 + start.minute);
            return AlertDialog(
              title: const Text('Tambah Slot Ketersediaan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: weekday,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Senin')),
                      DropdownMenuItem(value: 2, child: Text('Selasa')),
                      DropdownMenuItem(value: 3, child: Text('Rabu')),
                      DropdownMenuItem(value: 4, child: Text('Kamis')),
                      DropdownMenuItem(value: 5, child: Text('Jumat')),
                      DropdownMenuItem(value: 6, child: Text('Sabtu')),
                      DropdownMenuItem(value: 7, child: Text('Minggu')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => weekday = value);
                    },
                    decoration: const InputDecoration(labelText: 'Hari'),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: const Color(0xFFF7F4EE),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Jam mulai'),
                    subtitle: Text(start.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: start,
                      );
                      if (picked == null) {
                        return;
                      }
                      setState(() => start = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: const Color(0xFFF7F4EE),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: const Icon(Icons.stop_circle_outlined),
                    title: const Text('Jam selesai'),
                    subtitle: Text(end.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end,
                      );
                      if (picked == null) {
                        return;
                      }
                      setState(() => end = picked);
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _MiniHintChip(label: 'Usahakan slot 60-120 menit'),
                        _MiniHintChip(label: 'Hindari slot saling tumpang tindih'),
                      ],
                    ),
                  ),
                  if (isInvalid) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Jam selesai harus lebih besar dari jam mulai.',
                      style: TextStyle(
                        color: Color(0xFFB3261E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isInvalid
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submit != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(tutorAvailabilityControllerProvider)
          .addSlot(
            weekday: weekday,
            startHour: start.hour,
            startMinute: start.minute,
            endHour: end.hour,
            endMinute: end.minute,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot ketersediaan berhasil ditambahkan.'),
        ),
      );
    } on Exception catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menambahkan slot ketersediaan. Coba lagi. ${error.toString()}',
          ),
        ),
      );
    }
  }
}

class _AvailabilitySummaryCard extends StatelessWidget {
  const _AvailabilitySummaryCard({
    required this.totalSlots,
    required this.weeklyHoursLabel,
    required this.activeDays,
  });

  final int totalSlots;
  final String weeklyHoursLabel;
  final int activeDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF17324D), Color(0xFF2E5C74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pola Mengajar Mingguan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Atur slot yang realistis agar booking lebih mudah dipetakan dan bentrok lebih jarang terjadi.',
            style: TextStyle(color: Color(0xFFDDEAF0)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryPill(
                  label: 'Slot',
                  value: '$totalSlots',
                  background: const Color(0x26FFFFFF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryPill(
                  label: 'Jam/Minggu',
                  value: weeklyHoursLabel,
                  background: const Color(0x26FFFFFF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryPill(
                  label: 'Hari Aktif',
                  value: '$activeDays',
                  background: const Color(0x26FFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilityHintCard extends StatelessWidget {
  const _AvailabilityHintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF7B4B1A)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tips: kelompokkan jam mengajar yang berdekatan di hari yang sama agar tutor lebih mudah menerima booking paket 2x per minggu.',
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityDayCard extends StatelessWidget {
  const _AvailabilityDayCard({
    required this.weekdayLabel,
    required this.slotCount,
    required this.totalHoursLabel,
    required this.slots,
    required this.isLoading,
    required this.onDelete,
  });

  final String weekdayLabel;
  final int slotCount;
  final String totalHoursLabel;
  final List<TutorAvailabilitySlot> slots;
  final bool isLoading;
  final Future<void> Function(TutorAvailabilitySlot slot) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weekdayLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MiniHintChip(label: '$slotCount slot'),
              const SizedBox(width: 8),
              _MiniHintChip(label: '$totalHoursLabel jam'),
            ],
          ),
          const SizedBox(height: 12),
          ...slots.map(
            (slot) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${slot.startLabel} - ${slot.endLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading ? null : () => onDelete(slot),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.background,
  });

  final String label;
  final String value;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFDDEAF0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MiniHintChip extends StatelessWidget {
  const _MiniHintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE8D8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6B4D21),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyAvailabilityState extends StatelessWidget {
  const _EmptyAvailabilityState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(FluentIcons.calendar_checkmark_24_regular, size: 44),
          SizedBox(height: 12),
          Text(
            'Belum ada slot ketersediaan.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan jadwal mengajar agar murid bisa memilih paket dan slot yang sesuai dengan ritmemu.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
