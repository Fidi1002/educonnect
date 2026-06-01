class TutorStats {
  const TutorStats({
    required this.totalHoursTaught,
    required this.completedSessionsCount,
    required this.activeStudentsCount,
    required this.monthlyEarnings,
    required this.weekdaySessionCounts,
  });

  final double totalHoursTaught;
  final int completedSessionsCount;
  final int activeStudentsCount;
  final num monthlyEarnings;
  final List<int> weekdaySessionCounts; // Monday to Sunday counts (length: 7)

  factory TutorStats.empty() {
    return TutorStats(
      totalHoursTaught: 0.0,
      completedSessionsCount: 0,
      activeStudentsCount: 0,
      monthlyEarnings: 0,
      weekdaySessionCounts: List<int>.filled(7, 0),
    );
  }
}
