class TutorProfile {
  const TutorProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.bio,
    required this.subjects,
    required this.pricePerHour,
    required this.experienceYears,
    required this.experienceDescription,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.rating,
    required this.totalReviews,
    required this.isActive,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final String bio;
  final List<String> subjects;
  final num pricePerHour;
  final int experienceYears;
  final String experienceDescription;
  final String locationLabel;
  final double? latitude;
  final double? longitude;
  final String geohash;
  final double rating;
  final int totalReviews;
  final bool isActive;

  factory TutorProfile.empty(String uid) {
    return TutorProfile(
      uid: uid,
      displayName: '',
      photoUrl: '',
      bio: '',
      subjects: const <String>[],
      pricePerHour: 0,
      experienceYears: 0,
      experienceDescription: '',
      locationLabel: '',
      latitude: null,
      longitude: null,
      geohash: '',
      rating: 0,
      totalReviews: 0,
      isActive: true,
    );
  }
}
