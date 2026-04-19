import 'package:educonnect/features/auth/domain/models/app_user_role.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
  });

  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final AppUserRole role;

  factory AppUserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserProfile(
      uid: uid,
      email: (map['email'] as String?) ?? '',
      displayName:
          (map['display_name'] as String?) ?? (map['displayName'] as String?) ?? '',
      photoUrl: (map['photo_url'] as String?) ?? (map['photoUrl'] as String?) ?? '',
      role: AppUserRoleX.fromValue(map['role'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role': role.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
