import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalCacheService {
  const LocalCacheService._();

  static Box? _box;
  static Box? get box => _box;

  static Future<void> initialize({
    FlutterSecureStorage? secureStorageOverride,
    bool isTest = false,
  }) async {
    if (!isTest) {
      await Hive.initFlutter();
    }
    
    final secureStorage = secureStorageOverride ?? const FlutterSecureStorage();
    List<int> encryptionKey;

    try {
      final String? encryptionKeyBase64 = await secureStorage.read(key: 'educonnect_encryption_key');
      if (encryptionKeyBase64 == null) {
        encryptionKey = Hive.generateSecureKey();
        await secureStorage.write(
          key: 'educonnect_encryption_key',
          value: base64Url.encode(encryptionKey),
        );
      } else {
        encryptionKey = base64Url.decode(encryptionKeyBase64);
      }
    } catch (_) {
      // Fallback: Use a deterministic safe fallback key if secure storage is unavailable or fails
      encryptionKey = List<int>.generate(32, (i) => (i * 7 + 13) % 256);
    }

    try {
      _box = await Hive.openBox(
        'educonnect_cache',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (_) {
      // If decryption fails (e.g. key changed or box was previously unencrypted),
      // delete the local box and recreate it to avoid app startup crash
      await Hive.deleteBoxFromDisk('educonnect_cache');
      _box = await Hive.openBox(
        'educonnect_cache',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    }
  }

  static Future<void> cacheStudentBookings(
    String studentUid,
    List<Map<String, dynamic>> rows,
  ) async {
    await _box?.put('student_bookings_$studentUid', jsonEncode(rows));
  }

  static Future<List<Map<String, dynamic>>> getStudentBookings(
    String studentUid,
  ) async {
    final data = _box?.get('student_bookings_$studentUid') as String?;
    if (data == null) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> cacheTutorBookings(
    String tutorUid,
    List<Map<String, dynamic>> rows,
  ) async {
    await _box?.put('tutor_bookings_$tutorUid', jsonEncode(rows));
  }

  static Future<List<Map<String, dynamic>>> getTutorBookings(
    String tutorUid,
  ) async {
    final data = _box?.get('tutor_bookings_$tutorUid') as String?;
    if (data == null) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> cacheActiveTutors(List<Map<String, dynamic>> rows) async {
    await _box?.put('active_tutors', jsonEncode(rows));
  }

  static Future<List<Map<String, dynamic>>> getActiveTutors() async {
    final data = _box?.get('active_tutors') as String?;
    if (data == null) {
      return <Map<String, dynamic>>[];
    }
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
