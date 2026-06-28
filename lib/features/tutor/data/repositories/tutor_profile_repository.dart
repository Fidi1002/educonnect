import 'dart:io';

import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/core/utils/resilient_stream.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_stats.dart';
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
    return resilientStream(
      () => _client
          .from('tutors')
          .stream(primaryKey: ['uid'])
          .eq('uid', uid)
          .map((rows) {
            if (rows.isEmpty) {
              return null;
            }
            return _mapToProfile(uid: uid, tutorMap: rows.first);
          }),
    );
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
      'verification_status': profile.verificationStatus,
      'identity_card_url': profile.identityCardUrl,
      'certificate_url': profile.certificateUrl,
      'rejection_reason': profile.rejectionReason,
      'max_student_capacity': profile.maxStudentCapacity,
      'ktp_name': profile.ktpName,
      'nik': profile.nik,
      'birth_place': profile.birthPlace,
      'birth_date': profile.birthDate?.toIso8601String().split('T').first,
      'experience_cv': profile.experienceCv,
      'teaching_levels': profile.teachingLevels,
      'bank_name': profile.bankName,
      'bank_account_number': profile.bankAccountNumber,
      'languages': profile.languages,
      'introduction_video_url': profile.introductionVideoUrl,
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

  Future<String> uploadTutorDocument({
    required String uid,
    required File file,
    required String docType, // 'ktp' atau 'certificate'
  }) async {
    final bucket = _client.storage.from('tutor-documents');
    final extension = file.path.split('.').last.toLowerCase();
    final filePath =
        '$uid/${docType}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await bucket.uploadBinary(
      filePath,
      await file.readAsBytes(),
      fileOptions: const FileOptions(upsert: false),
    );

    return bucket.getPublicUrl(filePath);
  }



  Future<TutorStats> fetchTutorStats(String tutorUid) async {
    // 1. Fetch completed sessions
    final sessionsData = await _client
        .from('booking_sessions')
        .select('session_start, session_end')
        .eq('tutor_uid', tutorUid)
        .eq('status', 'confirmed');

    final sessions = sessionsData as List;
    final completedSessionsCount = sessions.length;

    var totalMinutes = 0;
    final weekdayCounts = List<int>.filled(7, 0);

    for (final row in sessions) {
      final startStr = row['session_start'] as String?;
      final endStr = row['session_end'] as String?;

      if (startStr != null && endStr != null) {
        final start = DateTime.tryParse(startStr)?.toLocal();
        final end = DateTime.tryParse(endStr)?.toLocal();
        if (start != null && end != null) {
          final duration = end.difference(start).inMinutes;
          totalMinutes += duration;

          final weekdayIndex = start.weekday - 1;
          if (weekdayIndex >= 0 && weekdayIndex < 7) {
            weekdayCounts[weekdayIndex] += 1;
          }
        }
      }
    }

    final totalHoursTaught = totalMinutes / 60.0;

    // 2. Fetch active students count (bookings paid)
    final bookingsData = await _client
        .from('bookings')
        .select('student_uid')
        .eq('tutor_uid', tutorUid)
        .eq('status', 'paid');

    final bookings = bookingsData as List;
    final activeStudentsCount = bookings
        .map((row) => row['student_uid'] as String? ?? '')
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .length;

    // Fetch total bookings count
    final allBookingsData = await _client
        .from('bookings')
        .select('student_uid')
        .eq('tutor_uid', tutorUid);
    final bookingsCount = (allBookingsData as List).length;

    // 3. Fetch monthly earnings
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toUtc().toIso8601String();
    final txsData = await _client
        .from('wallet_transactions')
        .select('amount')
        .eq('tutor_uid', tutorUid)
        .eq('type', 'credit')
        .gte('created_at', startOfMonth);

    final txs = txsData as List;
    final monthlyEarnings = txs.fold<num>(0, (sum, row) {
      final amount = row['amount'] as num? ?? 0;
      return sum + amount;
    });

    return TutorStats(
      totalHoursTaught: totalHoursTaught,
      completedSessionsCount: completedSessionsCount,
      activeStudentsCount: activeStudentsCount,
      monthlyEarnings: monthlyEarnings,
      weekdaySessionCounts: weekdayCounts,
      bookingsCount: bookingsCount,
    );
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
      consistencyScore:
          (tutorMap['consistency_score'] as num?)?.toDouble() ??
          (tutorMap['consistencyScore'] as num?)?.toDouble() ??
          0,
      isActive:
          (tutorMap['is_active'] as bool?) ??
          (tutorMap['isActive'] as bool?) ??
          true,
      verificationStatus:
          (tutorMap['verification_status'] as String?) ??
          (tutorMap['verificationStatus'] as String?) ??
          'none',
      identityCardUrl:
          (tutorMap['identity_card_url'] as String?) ??
          (tutorMap['identityCardUrl'] as String?),
      certificateUrl:
          (tutorMap['certificate_url'] as String?) ??
          (tutorMap['certificateUrl'] as String?),
      rejectionReason:
          (tutorMap['rejection_reason'] as String?) ??
          (tutorMap['rejectionReason'] as String?),
      maxStudentCapacity:
          (tutorMap['max_student_capacity'] as int?) ??
          (tutorMap['maxStudentCapacity'] as int?) ??
          2,
      ktpName: tutorMap['ktp_name'] as String?,
      nik: tutorMap['nik'] as String?,
      birthPlace: tutorMap['birth_place'] as String?,
      birthDate: tutorMap['birth_date'] != null
          ? DateTime.tryParse(tutorMap['birth_date'] as String)
          : null,
      experienceCv: tutorMap['experience_cv'] != null
          ? (tutorMap['experience_cv'] as List<dynamic>)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
          : null,
      teachingLevels: (tutorMap['teaching_levels'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      bankName: (tutorMap['bank_name'] as String?) ?? (tutorMap['bankName'] as String?),
      bankAccountNumber: (tutorMap['bank_account_number'] as String?) ?? (tutorMap['bankAccountNumber'] as String?),
      languages: (tutorMap['languages'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      introductionVideoUrl: (tutorMap['introduction_video_url'] as String?) ?? (tutorMap['introductionVideoUrl'] as String?),
    );
  }
}
