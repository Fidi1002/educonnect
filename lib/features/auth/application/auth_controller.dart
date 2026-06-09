import 'dart:io';

import 'package:educonnect/core/services/push_notification_service.dart';
import 'package:educonnect/features/auth/data/repositories/auth_repository.dart';
import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:educonnect/features/auth/domain/repositories/i_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

final authLoadingProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<AppAuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProfileProvider = StreamProvider<AppUserProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return const Stream<AppUserProfile?>.empty();
  }
  return ref.watch(userRepositoryProvider).watchUserProfile(authUser.uid);
});

final userProfileProvider = StreamProvider.autoDispose.family<AppUserProfile?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).watchUserProfile(uid);
});

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  IAuthRepository get _authRepository => _ref.read(authRepositoryProvider);
  IUserRepository get _userRepository => _ref.read(userRepositoryProvider);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _authRepository.signInWithEmail(
      email: email,
      password: password,
    );
    await _userRepository.upsertFromAuthUser(user);
  }

  Future<void> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = await _authRepository.registerWithEmail(
      fullName: fullName,
      email: email,
      password: password,
    );
    try {
      await _userRepository.upsertFromAuthUser(user);
    } on PostgrestException {
      if (!_authRepository.hasActiveSession) {
        throw const AuthException(
          'Akun berhasil dibuat. Cek email untuk verifikasi, lalu login.',
        );
      }
      rethrow;
    }
  }

  Future<void> signInWithGoogle() {
    return _authRepository.signInWithGoogle();
  }

  Future<void> sendPasswordReset(String email) {
    return _authRepository.sendPasswordResetEmail(email);
  }

  Future<void> setRole(AppUserRole role) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated');
    }
    await _userRepository.setRole(uid: user.uid, role: role);
  }

  Future<void> updateUserProfile({
    required String displayName,
    required String currentPhotoUrl,
    File? newPhoto,
    String? schoolLevel,
  }) async {
    return runAuthTask(() async {
      final user = _authRepository.currentUser;
      if (user == null) {
        throw StateError('User is not authenticated');
      }

      var photoUrl = currentPhotoUrl;
      if (newPhoto != null) {
        photoUrl = await _userRepository.uploadProfilePhoto(
          uid: user.uid,
          file: newPhoto,
        );
      }

      await _userRepository.updateProfile(
        uid: user.uid,
        displayName: displayName,
        photoUrl: photoUrl,
        schoolLevel: schoolLevel,
      );
    });
  }

  Future<void> signOut() async {
    await _ref.read(pushNotificationServiceProvider).markCurrentDeviceInactive();
    await _authRepository.signOut();
  }

  Future<T> runAuthTask<T>(Future<T> Function() action) async {
    _ref.read(authLoadingProvider.notifier).state = true;
    try {
      return await action();
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}
