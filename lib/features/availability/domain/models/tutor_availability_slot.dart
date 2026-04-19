class TutorAvailabilitySlot {
  const TutorAvailabilitySlot({
    required this.id,
    required this.tutorUid,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final String id;
  final String tutorUid;
  final int weekday; // ISO: Monday=1 ... Sunday=7
  final String startTime; // HH:mm:ss
  final String endTime; // HH:mm:ss
  final bool isActive;

  String get startLabel => _toShort(startTime);
  String get endLabel => _toShort(endTime);

  String get weekdayLabel {
    const labels = <int, String>{
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };
    return labels[weekday] ?? 'Hari $weekday';
  }

  factory TutorAvailabilitySlot.fromMap(Map<String, dynamic> map) {
    return TutorAvailabilitySlot(
      id: (map['id'] as String?) ?? '',
      tutorUid: (map['tutor_uid'] as String?) ?? '',
      weekday: (map['weekday'] as int?) ?? 1,
      startTime: (map['start_time'] as String?) ?? '08:00:00',
      endTime: (map['end_time'] as String?) ?? '09:00:00',
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }

  static String toDbTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  static String _toShort(String value) {
    final split = value.split(':');
    if (split.length < 2) {
      return value;
    }
    return '${split[0]}:${split[1]}';
  }
}
