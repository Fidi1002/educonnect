import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tutorAvailabilityRepositoryProvider =
    Provider<TutorAvailabilityRepository>((ref) {
      return TutorAvailabilityRepository(
        client: ref.watch(supabaseClientProvider),
      );
    });

class TutorAvailabilityRepository {
  TutorAvailabilityRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  Stream<List<TutorAvailabilitySlot>> watchTutorAvailability(String tutorUid) {
    return _client
        .from('tutor_availability')
        .stream(primaryKey: ['id'])
        .eq('tutor_uid', tutorUid)
        .order('weekday')
        .order('start_time')
        .map((rows) => rows.map(TutorAvailabilitySlot.fromMap).toList());
  }

  Future<void> addAvailabilitySlot({
    required String tutorUid,
    required int weekday,
    required String startTime,
    required String endTime,
  }) {
    return _client.from('tutor_availability').insert({
      'tutor_uid': tutorUid,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': true,
    });
  }

  Future<void> removeAvailabilitySlot(String slotId) {
    return _client.from('tutor_availability').delete().eq('id', slotId);
  }

  Future<List<DateTime>> fetchAvailableStartTimes({
    required String tutorUid,
    required DateTime date,
    required int durationMinutes,
  }) async {
    final localDate = DateTime(date.year, date.month, date.day);
    final dayStart = localDate.toUtc();
    final dayEnd = localDate.add(const Duration(days: 1)).toUtc();

    final availabilityRows = await _client
        .from('tutor_availability')
        .select('start_time,end_time')
        .eq('tutor_uid', tutorUid)
        .eq('weekday', localDate.weekday)
        .eq('is_active', true);

    final bookingRows = await _client
        .from('bookings')
        .select('session_start,session_end,status')
        .eq('tutor_uid', tutorUid)
        .gte('session_start', dayStart.toIso8601String())
        .lt('session_start', dayEnd.toIso8601String())
        .inFilter('status', <String>[
          BookingStatus.pending.value,
          BookingStatus.awaitingPayment.value,
          BookingStatus.paid.value,
          BookingStatus.completed.value,
        ]);

    final blockedIntervals = (bookingRows as List<dynamic>).map((row) {
      final map = row as Map<String, dynamic>;
      final start = DateTime.parse(
        map['session_start'] as String? ?? dayStart.toIso8601String(),
      ).toLocal();
      final end = DateTime.parse(
        map['session_end'] as String? ?? dayStart.toIso8601String(),
      ).toLocal();
      return (start, end);
    }).toList();

    final available = <DateTime>[];
    for (final row in (availabilityRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final startHm = _parseHm((map['start_time'] as String?) ?? '08:00:00');
      final endHm = _parseHm((map['end_time'] as String?) ?? '09:00:00');

      var candidate = DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
        startHm.$1,
        startHm.$2,
      );
      final slotEnd = DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
        endHm.$1,
        endHm.$2,
      );

      while (candidate
              .add(Duration(minutes: durationMinutes))
              .isBefore(slotEnd) ||
          candidate
              .add(Duration(minutes: durationMinutes))
              .isAtSameMomentAs(slotEnd)) {
        final candidateEnd = candidate.add(Duration(minutes: durationMinutes));
        final hasConflict = blockedIntervals.any(
          (interval) =>
              candidate.isBefore(interval.$2) &&
              candidateEnd.isAfter(interval.$1),
        );

        if (!hasConflict && candidate.isAfter(DateTime.now())) {
          available.add(candidate);
        }
        candidate = candidate.add(const Duration(minutes: 30));
      }
    }

    available.sort();
    final unique = <String, DateTime>{};
    for (final item in available) {
      unique[item.toIso8601String()] = item;
    }
    return unique.values.toList(growable: false);
  }

  (int, int) _parseHm(String value) {
    final split = value.split(':');
    final hour = split.isNotEmpty ? int.tryParse(split[0]) ?? 0 : 0;
    final minute = split.length > 1 ? int.tryParse(split[1]) ?? 0 : 0;
    return (hour, minute);
  }
}
