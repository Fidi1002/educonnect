import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:educonnect/features/availability/application/tutor_availability_controller.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_weekly_slot.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';

class TutorBookingSheet extends ConsumerStatefulWidget {
  const TutorBookingSheet({required this.tutor, super.key});
  
  final TutorProfile tutor;

  @override
  ConsumerState<TutorBookingSheet> createState() => _TutorBookingSheetState();
}

class _TutorBookingSheetState extends ConsumerState<TutorBookingSheet> {
  int _currentStep = 1; // 1 = Pilih Paket, 2 = Pilih Jadwal & Metode
  int _selectedMonths = 1;
  int _selectedSessionsPerWeek = 2; // Default to 2 sessions per week (supports 1, 2, or 3)

  final _selectedSlots = <TutorAvailabilitySlot>[];
  String _meetingType = 'online';
  final _locationController = TextEditingController();

  int get _totalSessions => _selectedMonths * 4 * _selectedSessionsPerWeek;
  num get _totalPrice => _totalSessions * widget.tutor.pricePerHour;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    if (profile != null && _locationController.text.isEmpty && profile.address != null && profile.address!.isNotEmpty) {
      _locationController.text = profile.address!;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _currentStep == 1
              ? _buildPackageSelectionStep(isDark)
              : _buildScheduleSelectionStep(isDark),
        ),
      ),
    );
  }

  // STEP 1: PILIH PAKET BELAJAR
  Widget _buildPackageSelectionStep(bool isDark) {
    return Column(
      key: const ValueKey('step_package'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Pilih Paket Belajar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Durasi Paket (Bulan)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [1, 2, 3, 6].map((months) {
            final isSelected = _selectedMonths == months;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Ink(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4B176E)
                        : (isDark ? const Color(0xFF28354E) : Colors.white),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4B176E)
                          : (isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMonths = months),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '$months Bln',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text(
          'Sesi per Minggu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [1, 2, 3].map((sessions) {
            final isSelected = _selectedSessionsPerWeek == sessions;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Ink(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4B176E)
                        : (isDark ? const Color(0xFF28354E) : Colors.white),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4B176E)
                          : (isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedSessionsPerWeek = sessions;
                      _selectedSlots.clear(); // Bersihkan slot lama jika frekuensi diubah
                    }),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '$sessions Sesi',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF28354E) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Sesi',
                    style: TextStyle(color: Color(0xFF718096)),
                  ),
                  Text(
                    '$_totalSessions sesi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Divider(
                height: 24, 
                color: isDark ? const Color(0xFF1B2336) : const Color(0xFFE2E8F0)
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Harga',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Rp $_totalPrice',
                    style: const TextStyle(
                      color: Color(0xFF4B176E),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _currentStep = 2),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4B176E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Lanjutkan ke Jadwal',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: PILIH JADWAL MINGGUAN & METODE
  Widget _buildScheduleSelectionStep(bool isDark) {
    final availabilityAsync = ref.watch(tutorAvailabilityByTutorProvider(widget.tutor.uid));
    final bookedSlotsAsync = ref.watch(tutorBookedWeeklySlotsProvider(widget.tutor.uid));

    return Column(
      key: const ValueKey('step_schedule'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              'Pilih $_selectedSessionsPerWeek Jadwal Mingguan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 48),
          child: Text(
            'Jadwal ini akan terkunci untuk seluruh periode paket belajarmu.',
            style: TextStyle(color: Color(0xFF718096), fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: availabilityAsync.when(
            data: (slots) {
              if (slots.isEmpty) {
                return const Center(
                  child: Text(
                    'Tutor belum mengatur ketersediaan waktu mengajar.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final bookedSlots = bookedSlotsAsync.valueOrNull ?? const [];
              final grouped = _groupAvailability(slots);
              final sortedKeys = grouped.keys.toList()
                ..sort(
                  (a, b) => _weekdaySortKey(a).compareTo(_weekdaySortKey(b)),
                );

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final day = sortedKeys[index];
                  final daySlots = grouped[day]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B176E),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: daySlots.map((slot) {
                          final isSelected = _selectedSlots.contains(slot);
                          final isBooked = bookedSlots.any((b) =>
                              b.weekday == slot.weekday &&
                              b.startTime == slot.startTime &&
                              b.endTime == slot.endTime);

                          return Ink(
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? (isDark ? const Color(0xFF2D1B22) : const Color(0xFFFFF5F5))
                                  : isSelected
                                      ? const Color(0xFF4B176E)
                                      : (isDark ? const Color(0xFF28354E) : Colors.white),
                              border: Border.all(
                                color: isBooked
                                    ? (isDark ? const Color(0xFF4E1D24) : const Color(0xFFFEB2B2))
                                    : isSelected
                                        ? const Color(0xFF4B176E)
                                        : (isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: isBooked
                                  ? null
                                  : () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedSlots.remove(slot);
                                        } else {
                                          if (_selectedSlots.length < _selectedSessionsPerWeek) {
                                            _selectedSlots.add(slot);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Kamu hanya bisa memilih $_selectedSessionsPerWeek jadwal.',
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      });
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: isBooked
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            FluentIcons.lock_closed_24_regular,
                                            size: 14,
                                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE53E3E),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${slot.startLabel} - ${slot.endLabel}',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE53E3E),
                                              decoration: TextDecoration.lineThrough,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(Penuh)',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFE53E3E),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '${slot.startLabel} - ${slot.endLabel}',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Gagal memuat jadwal')),
          ),
        ),
        const Divider(height: 24),
        const Text(
          'Metode Pertemuan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191622),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, size: 16),
                    SizedBox(width: 6),
                    Text('Online'),
                  ],
                ),
                selected: _meetingType == 'online',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _meetingType = 'online';
                    });
                  }
                },
                selectedColor: const Color(0xFF4B176E).withValues(alpha: 0.15),
                side: BorderSide(
                  color: _meetingType == 'online'
                      ? const Color(0xFF4B176E)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                labelStyle: TextStyle(
                  color: _meetingType == 'online'
                      ? const Color(0xFF4B176E)
                      : const Color(0xFF4A5568),
                  fontWeight: _meetingType == 'online' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16),
                    SizedBox(width: 6),
                    Text('Offline'),
                  ],
                ),
                selected: _meetingType == 'offline',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _meetingType = 'offline';
                    });
                  }
                },
                selectedColor: const Color(0xFF4B176E).withValues(alpha: 0.15),
                side: BorderSide(
                  color: _meetingType == 'offline'
                      ? const Color(0xFF4B176E)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                labelStyle: TextStyle(
                  color: _meetingType == 'offline'
                      ? const Color(0xFF4B176E)
                      : const Color(0xFF4A5568),
                  fontWeight: _meetingType == 'offline' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        if (_meetingType == 'offline') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Alamat / Lokasi Pertemuan',
              hintText: 'Contoh: Rumah/Cafe, Jl. Mawar No. 12',
              prefixIcon: const Icon(Icons.pin_drop, color: Color(0xFF4B176E)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4B176E), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _selectedSlots.length == _selectedSessionsPerWeek
                ? () => _submitBooking(ref)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4B176E),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Konfirmasi & Booking',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _submitBooking(WidgetRef ref) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Kamu harus login terlebih dahulu.');
      }

      if (_meetingType == 'offline' && _locationController.text.trim().isEmpty) {
        throw Exception('Alamat lokasi pertemuan offline wajib diisi.');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final ctrl = ref.read(bookingControllerProvider);
      final realSlots = _selectedSlots
          .map(
            (s) => BookingWeeklySlot(
              weekday: s.weekday,
              startTime: s.startTime,
              endTime: s.endTime,
            ),
          )
          .toList();

      await ctrl.createBooking(
        tutorUid: widget.tutor.uid,
        subject: widget.tutor.subjects.firstOrNull ?? 'Mapel Umum',
        packageStartDate: DateTime.now().add(const Duration(days: 1)),
        packageMonths: _selectedMonths,
        weeklySlots: realSlots,
        durationMinutes: 60,
        message: 'Saya siap untuk belajar',
        meetingType: _meetingType,
        meetingLocation: _meetingType == 'online'
            ? 'Online Classroom'
            : _locationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Tutup loading dialog
      Navigator.of(context).pop(); // Tutup bottom sheet

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil diajukan!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Tutup loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

// ----------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------

Map<String, List<TutorAvailabilitySlot>> _groupAvailability(
  List<TutorAvailabilitySlot> slots,
) {
  final grouped = <String, List<TutorAvailabilitySlot>>{};
  for (final slot in slots) {
    grouped.putIfAbsent(slot.weekdayLabel, () => []).add(slot);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  return grouped;
}

int _weekdaySortKey(String label) {
  const mapping = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };
  return mapping[label] ?? 99;
}
