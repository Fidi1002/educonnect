import 'dart:async';
import 'dart:io';

import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/core/services/local_cache_service.dart';
import 'package:educonnect/core/utils/resilient_stream.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/auth/domain/repositories/i_user_repository.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return SupabaseUserRepository(client: ref.watch(supabaseClientProvider));
});

class SupabaseUserRepository implements IUserRepository {
  SupabaseUserRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Future<AppUserProfile?> fetchUserProfile(String uid) async {
    try {
      final map = await _client
          .from('users')
          .select('uid,email,display_name,photo_url,role,school_level')
          .eq('uid', uid)
          .maybeSingle();
      if (map == null) {
        return null;
      }
      return AppUserProfile.fromMap(uid, map);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST116') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Stream<AppUserProfile?> watchUserProfile(String uid) {
    return resilientStream(
      () => _client
          .from('users')
          .stream(primaryKey: ['uid'])
          .eq('uid', uid)
          .map((rows) {
            if (rows.isEmpty) {
              return null;
            }
            return AppUserProfile.fromMap(uid, rows.first);
          }),
    );
  }

  @override
  Stream<List<TutorSummary>> watchActiveTutors({int limit = 25}) async* {
    final cached = await LocalCacheService.getActiveTutors();
    if (cached.isNotEmpty) {
      final limitedCached = cached.take(limit).toList();
      yield limitedCached.map(_mapTutorSummary).toList();
    }
    yield* resilientStream(
      () => _client
          .from('tutors')
          .stream(primaryKey: ['uid'])
          .eq('is_active', true)
          .order('rating', ascending: false)
          .map((rows) {
            unawaited(LocalCacheService.cacheActiveTutors(rows));
            final limitedRows = rows.take(limit).toList();
            return limitedRows.map(_mapTutorSummary).toList();
          }),
    );
  }

  @override
  Stream<List<TutorSummary>> watchNearbyTutors({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int maxResults = 500,
  }) async* {
    yield await _fetchNearbyTutors(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      maxResults: maxResults,
    );

    yield* Stream<int>.periodic(
      const Duration(seconds: 20),
      (tick) => tick,
    ).asyncMap((_) {
      return _fetchNearbyTutors(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        maxResults: maxResults,
      );
    });
  }

  @override
  Future<void> upsertFromAuthUser(AppAuthUser user) async {
    await _client.from('users').upsert({
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'uid');
  }

  @override
  Future<void> setRole({required String uid, required AppUserRole role}) async {
    await _client.from('users').upsert({
      'uid': uid,
      'role': role.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'uid');

    if (role != AppUserRole.tutor) {
      return;
    }

    final user = await _client
        .from('users')
        .select('display_name,photo_url')
        .eq('uid', uid)
        .maybeSingle();

    await _client.from('tutors').upsert({
      'uid': uid,
      'display_name': (user?['display_name'] as String?) ?? '',
      'photo_url': (user?['photo_url'] as String?) ?? '',
      'subjects': <String>['IPAS'],
      'bio': '',
      'price_per_hour': 0,
      'experience_years': 0,
      'experience_description': '',
      'location_label': '',
      'rating': 0,
      'total_reviews': 0,
      'is_active': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'uid');
  }

  @override
  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final bucket = _client.storage.from('tutor-photos'); // Reusing existing bucket
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

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String photoUrl,
    String? schoolLevel,
  }) async {
    await _client.from('users').update({
      'display_name': displayName.trim(),
      'photo_url': photoUrl.trim(),
      'school_level': schoolLevel,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('uid', uid);

    final userMap = await _client.from('users').select('role').eq('uid', uid).maybeSingle();
    if (userMap != null && userMap['role'] == AppUserRole.tutor.value) {
      await _client.from('tutors').update({
        'display_name': displayName.trim(),
        'photo_url': photoUrl.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('uid', uid);
    }
  }

  Future<List<TutorSummary>> _fetchNearbyTutors({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int maxResults,
  }) async {
    final rows = await _client.rpc(
      'get_nearby_tutors',
      params: {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
        'p_limit': maxResults,
      },
    );

    if (rows is! List) {
      return <TutorSummary>[];
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map(_mapTutorSummary)
        .toList();
  }

  TutorSummary _mapTutorSummary(Map<String, dynamic> map) {
    final subjects = (map['subjects'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .toList();

    final uid = (map['uid'] as String?) ?? '';
    return TutorSummary(
      uid: uid,
      name: _readString(map, 'display_name', fallbackKey: 'name').isNotEmpty
          ? _readString(map, 'display_name', fallbackKey: 'name')
          : 'Tutor ${uid.length >= 6 ? uid.substring(0, 6) : uid}',
      photoUrl: _readString(map, 'photo_url', fallbackKey: 'photoUrl'),
      subjects: subjects,
      rating: _readNum(map, 'rating').toDouble(),
      totalReviews: _readNum(
        map,
        'total_reviews',
        fallbackKey: 'totalReviews',
      ).toInt(),
      pricePerHour: _readNum(
        map,
        'price_per_hour',
        fallbackKey: 'pricePerHour',
      ),
      isActive: _readBool(map, 'is_active', fallbackKey: 'isActive'),
      latitude: _readDouble(map, 'latitude'),
      longitude: _readDouble(map, 'longitude'),
      consistencyScore: _readNum(
        map,
        'consistency_score',
        fallbackKey: 'consistencyScore',
      ).toDouble(),
      experienceYears: _readNum(
        map,
        'experience_years',
        fallbackKey: 'experienceYears',
      ).toInt(),
      distanceFromUserKm: map['distance_km'] is num
          ? (map['distance_km'] as num).toDouble()
          : null,
      recommendationScore: map['recommendation_score'] is num
          ? (map['recommendation_score'] as num).toDouble()
          : null,
    );
  }

  @override
  Stream<List<TutorSummary>> watchRecommendedTutors({
    required String studentUid,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int maxResults = 25,
  }) async* {
    yield await _fetchRecommendedTutors(
      studentUid: studentUid,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      maxResults: maxResults,
    );

    yield* Stream<int>.periodic(
      const Duration(seconds: 20),
      (tick) => tick,
    ).asyncMap((_) {
      return _fetchRecommendedTutors(
        studentUid: studentUid,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        maxResults: maxResults,
      );
    });
  }

  Future<List<TutorSummary>> _fetchRecommendedTutors({
    required String studentUid,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int maxResults,
  }) async {
    try {
      final rows = await _client.rpc(
        'get_recommended_tutors',
        params: {
          'p_student_uid': studentUid,
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_radius_km': radiusKm,
          'p_limit': maxResults,
        },
      );

      if (rows is! List) {
        return <TutorSummary>[];
      }

      return rows
          .whereType<Map<String, dynamic>>()
          .map(_mapTutorSummary)
          .toList();
    } catch (e) {
      // Fallback ke normal jika RPC gagal/belum dieksekusi secara lokal
      return _fetchNearbyTutors(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        maxResults: maxResults,
      );
    }
  }

  @override
  Future<void> updateStudentPreferences({
    required String uid,
    required List<String> preferredSubjects,
    required double maxPricePreference,
  }) async {
    await _client.from('users').update({
      'preferred_subjects': preferredSubjects,
      'max_price_preference': maxPricePreference,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('uid', uid);
  }

  String _readString(
    Map<String, dynamic> map,
    String key, {
    String? fallbackKey,
  }) {
    final primary = map[key];
    if (primary is String) {
      return primary;
    }
    if (fallbackKey == null) {
      return '';
    }
    final fallback = map[fallbackKey];
    return fallback is String ? fallback : '';
  }

  num _readNum(Map<String, dynamic> map, String key, {String? fallbackKey}) {
    final primary = map[key];
    if (primary is num) {
      return primary;
    }
    if (fallbackKey == null) {
      return 0;
    }
    final fallback = map[fallbackKey];
    return fallback is num ? fallback : 0;
  }

  double _readDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is num ? value.toDouble() : 0;
  }

  bool _readBool(Map<String, dynamic> map, String key, {String? fallbackKey}) {
    final primary = map[key];
    if (primary is bool) {
      return primary;
    }
    if (fallbackKey == null) {
      return false;
    }
    final fallback = map[fallbackKey];
    return fallback is bool ? fallback : false;
  }
}

