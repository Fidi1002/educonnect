import 'package:educonnect/features/availability/application/tutor_availability_controller.dart';
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
          if (slots.isEmpty) {
            return const Center(
              child: Text('Belum ada slot. Tambahkan jadwal ketersediaan.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: slots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final slot = slots[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(slot.weekdayLabel),
                  subtitle: Text('${slot.startLabel} - ${slot.endLabel}'),
                  trailing: IconButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus slot?'),
                                content: const Text(
                                  'Slot ini akan dihapus dari jadwal ketersediaan.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
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
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
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
                const SizedBox(height: 8),
                const Text('Gagal memuat jadwal ketersediaan.'),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(myTutorAvailabilityProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                      if (value == null) return;
                      setState(() => weekday = value);
                    },
                    decoration: const InputDecoration(labelText: 'Hari'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Jam mulai'),
                    subtitle: Text(start.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: start,
                      );
                      if (picked == null) return;
                      setState(() => start = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.stop_circle_outlined),
                    title: const Text('Jam selesai'),
                    subtitle: Text(end.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end,
                      );
                      if (picked == null) return;
                      setState(() => end = picked);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
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
        SnackBar(content: Text('Gagal menambah slot: ${error.toString()}')),
      );
    }
  }
}
