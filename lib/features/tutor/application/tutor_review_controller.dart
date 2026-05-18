import 'package:educonnect/features/tutor/data/repositories/tutor_review_repository.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tutorReviewsProvider = FutureProvider.family<List<TutorReview>, String>((ref, tutorUid) async {
  final repo = ref.watch(tutorReviewRepositoryProvider);
  return repo.getReviewsByTutor(tutorUid);
});

final tutorReviewControllerProvider = Provider<TutorReviewController>((ref) {
  return TutorReviewController(ref);
});

class TutorReviewController {
  const TutorReviewController(this._ref);

  final Ref _ref;

  Future<void> submitReview({
    required String tutorUid,
    required String studentUid,
    required String bookingId,
    required double rating,
    required String reviewText,
  }) async {
    final repo = _ref.read(tutorReviewRepositoryProvider);
    await repo.insertReview(
      tutorUid: tutorUid,
      studentUid: studentUid,
      bookingId: bookingId,
      rating: rating,
      reviewText: reviewText,
    );

    // Refresh daftar ulasan untuk tutor ini
    _ref.invalidate(tutorReviewsProvider(tutorUid));
  }
}
