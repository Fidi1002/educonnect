import 'dart:io';

import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/tutor/data/repositories/tutor_profile_repository.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tutorProfileLoadingProvider = StateProvider<bool>((ref) => false);

final myTutorProfileProvider = StreamProvider<TutorProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return const Stream<TutorProfile?>.empty();
  }
  return ref
      .watch(tutorProfileRepositoryProvider)
      .watchTutorProfile(authUser.uid);
});

final tutorProfileByIdProvider = FutureProvider.family<TutorProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(tutorProfileRepositoryProvider).fetchTutorProfile(uid);
});

final tutorProfileControllerProvider = Provider<TutorProfileController>((ref) {
  return TutorProfileController(ref);
});

class TutorProfileController {
  TutorProfileController(this._ref);

  final Ref _ref;

  TutorProfileRepository get _repository =>
      _ref.read(tutorProfileRepositoryProvider);

  String _requireUid() {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('User belum login.');
    }
    return user.uid;
  }

  Future<void> saveProfile(TutorProfile profile) async {
    await _runLoadingTask(() => _repository.upsertTutorProfile(profile));
  }

  Future<String> uploadPhoto(File file) async {
    final uid = _requireUid();
    return _runLoadingTask(
      () => _repository.uploadTutorPhoto(uid: uid, file: file),
    );
  }

  Future<String> uploadDocument(File file, String docType) async {
    final uid = _requireUid();
    return _runLoadingTask(
      () => _repository.uploadTutorDocument(uid: uid, file: file, docType: docType),
    );
  }



  Future<void> deactivateMyProfile() async {
    final uid = _requireUid();
    await _runLoadingTask(() => _repository.deactivateTutorProfile(uid));
  }

  Future<T> _runLoadingTask<T>(Future<T> Function() action) async {
    _ref.read(tutorProfileLoadingProvider.notifier).state = true;
    try {
      return await action();
    } finally {
      _ref.read(tutorProfileLoadingProvider.notifier).state = false;
    }
  }
}
