import 'package:educonnect/features/home/domain/models/tutor_summary.dart';

class TutorDiscoveryFilter {
  const TutorDiscoveryFilter({
    this.subject = 'All',
    this.minPrice,
    this.maxPrice,
    this.minRating = 0,
    this.maxDistanceKm,
  });

  final String subject;
  final num? minPrice;
  final num? maxPrice;
  final double minRating;
  final double? maxDistanceKm;

  bool get hasActiveFilters {
    return subject != 'All' ||
        minPrice != null ||
        maxPrice != null ||
        minRating > 0 ||
        maxDistanceKm != null;
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
  }) {
    return TutorDiscoveryFilter(
      subject: subject ?? this.subject,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: minRating ?? this.minRating,
      maxDistanceKm: clearMaxDistanceKm
          ? null
          : (maxDistanceKm ?? this.maxDistanceKm),
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
    final matchDistance =
        filter.maxDistanceKm == null ||
        tutor.distanceFromUserKm == null ||
        tutor.distanceFromUserKm! <= filter.maxDistanceKm!;
    return matchQuery &&
        matchSubject &&
        matchMinPrice &&
        matchMaxPrice &&
        matchRating &&
        matchDistance;
  }).toList();
}
