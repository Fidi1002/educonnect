import 'package:educonnect/core/config/app_config.dart';
import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(client: ref.watch(supabaseClientProvider));
});

class AuthRepository {
  AuthRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Stream<AppAuthUser?> authStateChanges() async* {
    yield currentUser;
    yield* _client.auth.onAuthStateChange.map(
      (event) => _toAppAuthUser(event.session?.user),
    );
  }

  AppAuthUser? get currentUser => _toAppAuthUser(_client.auth.currentUser);
  bool get hasActiveSession => _client.auth.currentSession != null;

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

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
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
