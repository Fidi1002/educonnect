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
    required this.consistencyScore,
    required this.isActive,
    this.verificationStatus = 'none',
    this.identityCardUrl,
    this.certificateUrl,
    this.rejectionReason,
    this.maxStudentCapacity = 2,
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
  final double consistencyScore;
  final bool isActive;
  final String verificationStatus;
  final String? identityCardUrl;
  final String? certificateUrl;
  final String? rejectionReason;
  final int maxStudentCapacity;

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
      consistencyScore: 0,
      isActive: false,
      verificationStatus: 'none',
      identityCardUrl: null,
      certificateUrl: null,
      rejectionReason: null,
      maxStudentCapacity: 2,
    );
  }

  TutorProfile copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? subjects,
    num? pricePerHour,
    int? experienceYears,
    String? experienceDescription,
    String? locationLabel,
    double? latitude,
    double? longitude,
    String? geohash,
    double? rating,
    int? totalReviews,
    double? consistencyScore,
    bool? isActive,
    String? verificationStatus,
    String? identityCardUrl,
    String? certificateUrl,
    String? rejectionReason,
    int? maxStudentCapacity,
  }) {
    return TutorProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      subjects: subjects ?? this.subjects,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      experienceYears: experienceYears ?? this.experienceYears,
      experienceDescription: experienceDescription ?? this.experienceDescription,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      isActive: isActive ?? this.isActive,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      identityCardUrl: identityCardUrl ?? this.identityCardUrl,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      maxStudentCapacity: maxStudentCapacity ?? this.maxStudentCapacity,
    );
  }
}
