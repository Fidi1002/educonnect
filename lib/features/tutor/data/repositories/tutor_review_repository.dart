import 'package:educonnect/features/tutor/domain/models/tutor_review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tutorReviewRepositoryProvider = Provider<TutorReviewRepository>((ref) {
  return TutorReviewRepository(Supabase.instance.client);
});

class TutorReviewRepository {
  const TutorReviewRepository(this._client);

  final SupabaseClient _client;

  Future<List<TutorReview>> getReviewsByTutor(String tutorUid) async {
    // Join dengan tabel users untuk mendapatkan nama dan foto murid
    final data = await _client
        .from('tutor_reviews')
        .select('''
          *,
          student:student_uid (
            display_name,
            photo_url
          )
        ''')
        .eq('tutor_uid', tutorUid)
        .order('created_at', ascending: false);

    return data.map((json) {
      final student = json['student'] as Map<String, dynamic>? ?? {};
      return TutorReview.fromJson({
        ...json,
        'student_name': student['display_name'],
        'student_photo_url': student['photo_url'],
      });
    }).toList();
  }

  Future<void> insertReview({
    required String tutorUid,
    required String studentUid,
    required String bookingId,
    required double rating,
    required String reviewText,
  }) async {
    await _client.from('tutor_reviews').insert({
      'tutor_uid': tutorUid,
      'student_uid': studentUid,
      'booking_id': bookingId,
      'rating': rating,
      'review_text': reviewText.trim(),
    });
  }

  Future<bool> hasReviewed(String bookingId) async {
    final response = await _client
        .from('tutor_reviews')
        .select('id')
        .eq('booking_id', bookingId)
        .maybeSingle();
    return response != null;
  }
}
