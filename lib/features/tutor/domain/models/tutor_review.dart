class TutorReview {
  const TutorReview({
    required this.id,
    required this.tutorUid,
    required this.studentUid,
    this.bookingId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    this.studentName,
    this.studentPhotoUrl,
  });

  final String id;
  final String tutorUid;
  final String studentUid;
  final String? bookingId;
  final double rating;
  final String reviewText;
  final DateTime createdAt;
  final String? studentName;
  final String? studentPhotoUrl;

  factory TutorReview.fromJson(Map<String, dynamic> json) {
    return TutorReview(
      id: json['id'] as String? ?? '',
      tutorUid: json['tutor_uid'] as String? ?? '',
      studentUid: json['student_uid'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewText: json['review_text'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      studentName: json['student_name'] as String?,
      studentPhotoUrl: json['student_photo_url'] as String?,
    );
  }
}
