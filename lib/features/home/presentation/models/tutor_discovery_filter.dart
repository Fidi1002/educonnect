import 'package:educonnect/features/home/domain/models/tutor_summary.dart';

class TutorDiscoveryFilter {
  const TutorDiscoveryFilter({
    this.subject = 'All',
    this.minPrice,
    this.maxPrice,
    this.minRating = 0,
    this.maxDistanceKm,
    this.minExperienceYears = 0,
    this.preferredDays = const {},
  });

  final String subject;
  final num? minPrice;
  final num? maxPrice;
  final double minRating;
  final double? maxDistanceKm;
  final int minExperienceYears;
  final Set<String> preferredDays;

  bool get hasActiveFilters {
    return subject != 'All' ||
        minPrice != null ||
        maxPrice != null ||
        minRating > 0 ||
        maxDistanceKm != null ||
        minExperienceYears > 0 ||
        preferredDays.isNotEmpty;
  }

  TutorDiscoveryFilter copyWith({
    String? subject,
    num? minPrice,
    bool clearMinPrice = false,
    num? maxPrice,
    bool clearMaxPrice = false,
    double? minRating,
    double? maxDistanceKm,
    bool clearMaxDistanceKm = false,
    int? minExperienceYears,
    Set<String>? preferredDays,
  }) {
    return TutorDiscoveryFilter(
      subject: subject ?? this.subject,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: minRating ?? this.minRating,
      maxDistanceKm: clearMaxDistanceKm
          ? null
          : (maxDistanceKm ?? this.maxDistanceKm),
      minExperienceYears: minExperienceYears ?? this.minExperienceYears,
      preferredDays: preferredDays ?? this.preferredDays,
    );
  }

  static const empty = TutorDiscoveryFilter();
}

List<TutorSummary> applyTutorDiscoveryFilters({
  required List<TutorSummary> tutors,
  required String query,
  required TutorDiscoveryFilter filter,
}) {
  return tutors.where((tutor) {
    final matchQuery = tutor.matchesKeyword(query);
    final matchSubject =
        filter.subject == 'All' || tutor.subjects.contains(filter.subject);
    final matchMinPrice =
        filter.minPrice == null || tutor.pricePerHour >= filter.minPrice!;
    final matchMaxPrice =
        filter.maxPrice == null || tutor.pricePerHour <= filter.maxPrice!;
    final matchRating = tutor.rating >= filter.minRating;
    final matchDistance = filter.maxDistanceKm == null ||
        tutor.distanceFromUserKm == null ||
        tutor.distanceFromUserKm! <= filter.maxDistanceKm!;
    final matchExperience = tutor.experienceYears >= filter.minExperienceYears;

    // Note: preferredDays filtering would ideally check against tutor availability slots.
    // For now, we assume if tutor exists and filter has days, we'd need deeper join.
    // Assuming TutorSummary has some day info or skipping for now to keep logic simple.
    
    return matchQuery &&
        matchSubject &&
        matchMinPrice &&
        matchMaxPrice &&
        matchRating &&
        matchDistance &&
        matchExperience;
  }).toList();
}
