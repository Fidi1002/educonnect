class TutorSummary {
  const TutorSummary({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.subjects,
    required this.rating,
    required this.totalReviews,
    required this.pricePerHour,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    required this.consistencyScore,
    required this.experienceYears,
    this.distanceFromUserKm,
    this.recommendationScore,
  });

  final String uid;
  final String name;
  final String photoUrl;
  final List<String> subjects;
  final double rating;
  final int totalReviews;
  final num pricePerHour;
  final bool isActive;
  final double latitude;
  final double longitude;
  final double consistencyScore;
  final int experienceYears;
  final double? distanceFromUserKm;
  final double? recommendationScore;

  bool matchesKeyword(String query) {
    if (query.isEmpty) {
      return true;
    }
    final keyword = query.toLowerCase();
    return name.toLowerCase().contains(keyword) ||
        subjects.any((subject) => subject.toLowerCase().contains(keyword));
  }
}

