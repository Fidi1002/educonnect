import 'dart:io';

import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tutorProfileRepositoryProvider = Provider<TutorProfileRepository>((ref) {
  return TutorProfileRepository(client: ref.watch(supabaseClientProvider));
});

class TutorProfileRepository {
  TutorProfileRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Future<TutorProfile?> fetchTutorProfile(String uid) async {
    final tutorMap = await _client
        .from('tutors')
        .select()
        .eq('uid', uid)
        .maybeSingle();
    if (tutorMap == null) {
      return null;
    }
    return _mapToProfile(uid: uid, tutorMap: tutorMap);
  }

  Stream<TutorProfile?> watchTutorProfile(String uid) {
    return _client
        .from('tutors')
        .stream(primaryKey: ['uid'])
        .eq('uid', uid)
        .map((rows) {
          if (rows.isEmpty) {
            return null;
          }
          return _mapToProfile(uid: uid, tutorMap: rows.first);
        });
  }

  Future<void> upsertTutorProfile(TutorProfile profile) async {
    await _client.from('users').upsert({
      'uid': profile.uid,
      'display_name': profile.displayName.trim(),
      'photo_url': profile.photoUrl.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'uid');

    await _client.from('tutors').upsert({
      'uid': profile.uid,
      'display_name': profile.displayName.trim(),
      'photo_url': profile.photoUrl.trim(),
      'bio': profile.bio.trim(),
      'subjects': profile.subjects,
      'price_per_hour': profile.pricePerHour,
      'experience_years': profile.experienceYears,
      'experience_description': profile.experienceDescription.trim(),
      'location_label': profile.locationLabel.trim(),
      'latitude': profile.latitude,
      'longitude': profile.longitude,
      'geohash': profile.geohash,
      'is_active': profile.isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'uid');
  }

  Future<String> uploadTutorPhoto({
    required String uid,
    required File file,
  }) async {
    final bucket = _client.storage.from('tutor-photos');
    final extension = file.path.split('.').last.toLowerCase();
    final filePath =
        '$uid/profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await bucket.uploadBinary(
      filePath,
      await file.readAsBytes(),
      fileOptions: const FileOptions(upsert: false),
    );

    return bucket.getPublicUrl(filePath);
  }

  Future<void> deactivateTutorProfile(String uid) async {
    await _client.from('tutors').update({'is_active': false}).eq('uid', uid);
  }

  TutorProfile _mapToProfile({
    required String uid,
    required Map<String, dynamic> tutorMap,
  }) {
    return TutorProfile(
      uid: uid,
      displayName:
          (tutorMap['display_name'] as String?) ??
          (tutorMap['displayName'] as String?) ??
          '',
      photoUrl:
          (tutorMap['photo_url'] as String?) ??
          (tutorMap['photoUrl'] as String?) ??
          '',
      bio: tutorMap['bio'] as String? ?? '',
      subjects: (tutorMap['subjects'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      pricePerHour:
          (tutorMap['price_per_hour'] as num?) ??
          (tutorMap['pricePerHour'] as num?) ??
          0,
      experienceYears:
          (tutorMap['experience_years'] as int?) ??
          (tutorMap['experienceYears'] as int?) ??
          0,
      experienceDescription:
          (tutorMap['experience_description'] as String?) ??
          (tutorMap['experienceDescription'] as String?) ??
          '',
      locationLabel:
          (tutorMap['location_label'] as String?) ??
          (tutorMap['locationLabel'] as String?) ??
          '',
      latitude: (tutorMap['latitude'] as num?)?.toDouble(),
      longitude: (tutorMap['longitude'] as num?)?.toDouble(),
      geohash: tutorMap['geohash'] as String? ?? '',
      rating: (tutorMap['rating'] as num? ?? 0).toDouble(),
      totalReviews:
          (tutorMap['total_reviews'] as int?) ??
          (tutorMap['totalReviews'] as int?) ??
          0,
      isActive:
          (tutorMap['is_active'] as bool?) ??
          (tutorMap['isActive'] as bool?) ??
          true,
    );
  }
}
