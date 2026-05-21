import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/home/application/nearby_tutor_controller.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recommendedTutorsProvider = StreamProvider<List<TutorSummary>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  final position = ref.watch(userLocationProvider);
  final radiusKm = ref.watch(searchRadiusKmProvider);

  if (user == null || position == null) {
    return const Stream<List<TutorSummary>>.empty();
  }

  return ref.watch(userRepositoryProvider).watchRecommendedTutors(
        studentUid: user.uid,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: radiusKm,
      );
});

final recommendationControllerProvider = Provider<RecommendationController>((ref) {
  return RecommendationController(ref);
});

class RecommendationController {
  RecommendationController(this._ref);

  final Ref _ref;

  Future<void> updatePreferences({
    required List<String> preferredSubjects,
    required double maxPricePreference,
  }) async {
    final authState = _ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) {
      return;
    }

    await _ref.read(userRepositoryProvider).updateStudentPreferences(
          uid: user.uid,
          preferredSubjects: preferredSubjects,
          maxPricePreference: maxPricePreference,
        );

    // Refresh state profile agar perubahan langsung memicu pembaruan list rekomendasi
    _ref.invalidate(authStateProvider);
  }
}
