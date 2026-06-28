import 'package:educonnect/core/config/app_config.dart';
import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return SupabaseAuthRepository(client: ref.watch(supabaseClientProvider));
});

class SupabaseAuthRepository implements IAuthRepository {
  SupabaseAuthRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Stream<AppAuthUser?> authStateChanges() async* {
    yield currentUser;
    yield* _client.auth.onAuthStateChange.map(
      (event) => _toAppAuthUser(event.session?.user),
    );
  }

  @override
  AppAuthUser? get currentUser => _toAppAuthUser(_client.auth.currentUser);
  @override
  bool get hasActiveSession => _client.auth.currentSession != null;

  @override
  Future<AppAuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Login gagal. User tidak ditemukan.');
    }
    return _toAppAuthUser(user)!;
  }

  @override
  Future<AppAuthUser> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': fullName.trim()},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Registrasi gagal. User tidak ditemukan.');
    }
    return _toAppAuthUser(user)!;
  }

  @override
  Future<void> signInWithGoogle() {
    if (!AppConfig.enableGoogleAuth) {
      throw const AuthException(
        'Login Google belum diaktifkan pada aplikasi ini.',
      );
    }
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.supabaseGoogleRedirectUrl,
    );
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  AppAuthUser? _toAppAuthUser(User? user) {
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final displayName = (metadata['display_name'] as String?)?.trim() ?? '';
    final photoUrl = (metadata['avatar_url'] as String?)?.trim() ?? '';

    return AppAuthUser(
      uid: user.id,
      email: user.email ?? '',
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
