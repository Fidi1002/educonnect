import 'dart:io';

import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';

abstract class IUserRepository {
  Future<AppUserProfile?> fetchUserProfile(String uid);
  Stream<AppUserProfile?> watchUserProfile(String uid);
  
  Stream<List<TutorSummary>> watchActiveTutors({int limit = 25});
  
  Stream<List<TutorSummary>> watchNearbyTutors({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int maxResults = 500,
  });

  Future<void> upsertFromAuthUser(AppAuthUser user);
  Future<void> setRole({required String uid, required AppUserRole role});
  
  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  });

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String photoUrl,
    String? schoolLevel,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    String? preferredTutorGender,
  });

  Stream<List<TutorSummary>> watchRecommendedTutors({
    required String studentUid,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int maxResults = 25,
  });

  Future<void> updateStudentPreferences({
    required String uid,
    required List<String> preferredSubjects,
    required double maxPricePreference,
  });
}
