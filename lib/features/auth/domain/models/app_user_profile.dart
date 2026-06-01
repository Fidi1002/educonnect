import 'package:educonnect/features/auth/domain/models/app_user_role.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    this.preferredSubjects = const <String>[],
    this.maxPricePreference = 0.0,
    this.schoolLevel,
  });

  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final AppUserRole role;
  final List<String> preferredSubjects;
  final double maxPricePreference;
  final String? schoolLevel;

  factory AppUserProfile.fromMap(String uid, Map<String, dynamic> map) {
    final preferred = (map['preferred_subjects'] as List<dynamic>? ??
            map['preferredSubjects'] as List<dynamic>? ??
            const <dynamic>[])
        .map((item) => item.toString())
        .toList();
    final maxPrice = map['max_price_preference'] is num
        ? (map['max_price_preference'] as num).toDouble()
        : map['maxPricePreference'] is num
            ? (map['maxPricePreference'] as num).toDouble()
            : 0.0;

    return AppUserProfile(
      uid: uid,
      email: (map['email'] as String?) ?? '',
      displayName: (map['display_name'] as String?) ??
          (map['displayName'] as String?) ??
          '',
      photoUrl: (map['photo_url'] as String?) ??
          (map['photoUrl'] as String?) ??
          '',
      role: AppUserRoleX.fromValue(map['role'] as String?),
      preferredSubjects: preferred,
      maxPricePreference: maxPrice,
      schoolLevel: (map['school_level'] as String?) ?? (map['schoolLevel'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role': role.value,
      'preferred_subjects': preferredSubjects,
      'max_price_preference': maxPricePreference,
      'school_level': schoolLevel,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

