class BookingWeeklySlot {
  const BookingWeeklySlot({
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  final int weekday;
  final String startTime;
  final String endTime;

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

  String get timeLabel {
    final start = _toHm(startTime);
    final end = _toHm(endTime);
    return '$start - $end';
  }

  Map<String, dynamic> toMap() {
    return {'weekday': weekday, 'start_time': startTime, 'end_time': endTime};
  }

  factory BookingWeeklySlot.fromMap(Map<String, dynamic> map) {
    return BookingWeeklySlot(
      weekday: (map['weekday'] as int?) ?? 1,
      startTime: (map['start_time'] as String?) ?? '08:00:00',
      endTime: (map['end_time'] as String?) ?? '09:00:00',
    );
  }

  static String _toHm(String value) {
    final split = value.split(':');
    if (split.length < 2) {
      return value;
    }
    return '${split[0]}:${split[1]}';
  }
}
