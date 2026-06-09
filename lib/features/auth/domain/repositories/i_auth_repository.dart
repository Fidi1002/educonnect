import 'package:educonnect/features/auth/domain/models/auth_user.dart';

abstract class IAuthRepository {
  Stream<AppAuthUser?> authStateChanges();
  AppAuthUser? get currentUser;
  bool get hasActiveSession;
  
  Future<AppAuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppAuthUser> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
}
