import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeTutorsProvider = StreamProvider<List<TutorSummary>>((ref) {
  return ref.watch(userRepositoryProvider).watchActiveTutors();
});
