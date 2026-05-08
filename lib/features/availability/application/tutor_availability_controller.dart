import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/availability/data/repositories/tutor_availability_repository.dart';
import 'package:educonnect/features/availability/domain/models/tutor_availability_slot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tutorAvailabilityLoadingProvider = StateProvider<bool>((ref) => false);

final myTutorAvailabilityProvider = StreamProvider<List<TutorAvailabilitySlot>>(
  (ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Stream<List<TutorAvailabilitySlot>>.empty();
    }
    return ref
        .watch(tutorAvailabilityRepositoryProvider)
        .watchTutorAvailability(user.uid);
  },
);

final tutorAvailabilityByTutorProvider = StreamProvider.autoDispose
    .family<List<TutorAvailabilitySlot>, String>((ref, tutorUid) {
  return ref
      .watch(tutorAvailabilityRepositoryProvider)
      .watchTutorAvailability(tutorUid);
});

class AvailableTimesInput {
  const AvailableTimesInput({
    required this.tutorUid,
    required this.date,
    required this.durationMinutes,
  });

  final String tutorUid;
  final DateTime date;
  final int durationMinutes;
}

final availableTimesProvider = FutureProvider.autoDispose
    .family<List<DateTime>, AvailableTimesInput>((ref, input) {
      return ref
          .watch(tutorAvailabilityRepositoryProvider)
          .fetchAvailableStartTimes(
            tutorUid: input.tutorUid,
            date: input.date,
            durationMinutes: input.durationMinutes,
          );
    });

final tutorAvailabilityControllerProvider =
    Provider<TutorAvailabilityController>((ref) {
      return TutorAvailabilityController(ref);
    });

class TutorAvailabilityController {
  TutorAvailabilityController(this._ref);

  final Ref _ref;

  TutorAvailabilityRepository get _repository =>
      _ref.read(tutorAvailabilityRepositoryProvider);

  String _requireUid() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('User belum login.');
    }
    return user.uid;
  }

  Future<void> addSlot({
    required int weekday,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError('Weekday harus 1-7');
    }
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (end <= start) {
      throw ArgumentError('Jam selesai harus lebih besar dari jam mulai.');
    }

    final tutorUid = _requireUid();
    final existingSlots = await _repository.fetchTutorAvailability(tutorUid);
    final hasOverlap = existingSlots.any((slot) {
      if (slot.weekday != weekday) {
        return false;
      }
      final existingStart = _timeToMinutes(slot.startTime);
      final existingEnd = _timeToMinutes(slot.endTime);
      return start < existingEnd && end > existingStart;
    });
    if (hasOverlap) {
      throw ArgumentError(
        'Slot bentrok dengan jadwal yang sudah ada di hari yang sama.',
      );
    }

    await _runLoadingTask(
      () => _repository.addAvailabilitySlot(
        tutorUid: tutorUid,
        weekday: weekday,
        startTime: TutorAvailabilitySlot.toDbTime(startHour, startMinute),
        endTime: TutorAvailabilitySlot.toDbTime(endHour, endMinute),
      ),
    );
  }

  Future<void> removeSlot(String slotId) {
    return _runLoadingTask(() => _repository.removeAvailabilitySlot(slotId));
  }

  Future<T> _runLoadingTask<T>(Future<T> Function() action) async {
    _ref.read(tutorAvailabilityLoadingProvider.notifier).state = true;
    try {
      return await action();
    } finally {
      _ref.read(tutorAvailabilityLoadingProvider.notifier).state = false;
    }
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return (hour * 60) + minute;
  }
}
